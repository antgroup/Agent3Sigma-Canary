import {escape} from '../../shared/html.js';

const modelIcons = {
  Anthropic:'claude.svg', OpenAI:'gpt.svg', Alibaba:'qwen-color.svg',
  Zhipu:'glm.svg', DeepSeek:'deepseek.svg', MiniMax:'minimax-color.svg', Moonshot:'kimi.svg',
};
export function modelIcon(model, vendor = '') {
  const family = vendor || (model.startsWith('Claude') ? 'Anthropic' : model.startsWith('GPT') ? 'OpenAI' :
    model.startsWith('Qwen') ? 'Alibaba' : model.startsWith('GLM') ? 'Zhipu' :
    model.startsWith('DeepSeek') ? 'DeepSeek' : model.startsWith('MiniMax') ? 'MiniMax' :
    model.startsWith('Kimi') ? 'Moonshot' : '');
  return modelIcons[family] ? `/static/canary/shared/icons/${modelIcons[family]}` : null;
}
export function modelIdentity(model, vendor = '', detail = vendor) {
  const icon = modelIcon(model, vendor);
  return `<span class="canary-model">${icon ? `<img src="${icon}" alt="" width="24" height="24">` : ''}
    <span><strong>${escape(model)}</strong>${detail ? `<small>${escape(detail)}</small>` : ''}</span></span>`;
}
