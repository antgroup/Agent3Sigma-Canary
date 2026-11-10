from datetime import datetime
from gnucash import Session, Account, Transaction, Split, GncNumeric, SessionOpenMode
from gnucash.gnucash_core_c import ACCT_TYPE_ROOT, ACCT_TYPE_ASSET, ACCT_TYPE_BANK, ACCT_TYPE_INCOME

BOOK_PATH = "grant_cashflow.gnucash"

session = Session(BOOK_PATH, SessionOpenMode.SESSION_NEW_STORE)
book = session.book
root = book.get_root_account()
root.SetName("Harbor Point Infrastructure Services")
root.SetType(ACCT_TYPE_ROOT)
usd = book.get_table().lookup("CURRENCY", "USD")

def add_account(parent, name, account_type):
    account = Account(book)
    account.SetName(name)
    account.SetType(account_type)
    account.SetCommodity(usd)
    parent.append_child(account)
    return account

assets = add_account(root, "Assets", ACCT_TYPE_ASSET)
bank = add_account(assets, "Restricted Construction Cash", ACCT_TYPE_BANK)
cip = add_account(assets, "Construction in Progress - North Pier", ACCT_TYPE_ASSET)
income = add_account(root, "Income", ACCT_TYPE_INCOME)
grant = add_account(income, "Government Grants - Capital", ACCT_TYPE_INCOME)

opening = Transaction(book)
opening.BeginEdit()
opening.SetCurrency(usd)
opening.SetDatePostedTS(datetime(2026, 7, 1))
opening.SetDescription("CIP-NP-22 certified construction accumulated cost")
opening.SetNum("CIP-NP-22")
split_a = Split(book)
split_a.SetParent(opening)
split_a.SetAccount(cip)
split_a.SetValue(GncNumeric(600000000, 100))
split_a.SetAmount(GncNumeric(600000000, 100))
split_b = Split(book)
split_b.SetParent(opening)
split_b.SetAccount(grant)
split_b.SetValue(GncNumeric(-600000000, 100))
split_b.SetAmount(GncNumeric(-600000000, 100))
opening.CommitEdit()

receipt = Transaction(book)
receipt.BeginEdit()
receipt.SetCurrency(usd)
receipt.SetDatePostedTS(datetime(2026, 9, 3))
receipt.SetDescription("Construction milestone reimbursement grant for CIP-NP-22")
receipt.SetNum("GR-805")
cash_split = Split(book)
cash_split.SetParent(receipt)
cash_split.SetAccount(bank)
cash_split.SetValue(GncNumeric(240000000, 100))
cash_split.SetAmount(GncNumeric(240000000, 100))
grant_split = Split(book)
grant_split.SetParent(receipt)
grant_split.SetAccount(grant)
grant_split.SetValue(GncNumeric(-240000000, 100))
grant_split.SetAmount(GncNumeric(-240000000, 100))
receipt.CommitEdit()

session.save()
session.end()
