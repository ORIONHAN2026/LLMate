import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 业务类型列表
final List<Map<String, dynamic>> businessTypes = [
  {
    'name': '代码分析',
    'icon': Icons.code,
    'description': '代码审查、调试、重构和优化建议',
    'color': Colors.blue,
  },
  {
    'name': '法律查询',
    'icon': Icons.gavel,
    'description': '法律条文查询、合同审查、法律咨询',
    'color': Colors.purple,
  },
  {
    'name': '合规管理',
    'icon': Icons.security,
    'description': '企业合规检查、风险评估、政策解读',
    'color': Colors.orange,
  },
  {
    'name': '通用对话',
    'icon': Icons.chat,
    'description': '日常对话、问答、知识查询',
    'color': Colors.green,
  },
  {
    'name': '文档处理',
    'icon': Icons.description,
    'description': '文档总结、翻译、格式转换',
    'color': Colors.indigo,
  },
  {
    'name': '数据分析',
    'icon': Icons.analytics,
    'description': '数据处理、图表生成、统计分析',
    'color': Colors.teal,
  },
];

// 业务类型对应的大模型
final Map<String, List<Map<String, dynamic>>> businessModels = {
  '代码分析': [
    {
      'name': 'DeepSeek-Coder',
      'baseName': 'deepseek-coder',
      'sizes': ['0.6B', '1.7B', '4B', '8B', '14B', '30B', '32B', '235B'],
      'description': '专为代码理解和生成任务优化的模型',
    },
    {
      'name': 'CodeLlama',
      'baseName': 'codellama',
      'sizes': ['7B', '13B', '34B'],
      'description': '基于Llama2的代码生成模型',
    },
    {
      'name': 'Qwen2.5-Coder',
      'baseName': 'qwen2.5-coder',
      'sizes': ['1.5B', '7B', '14B', '32B'],
      'description': '阿里巴巴开发的代码专用模型',
    },
  ],
  '法律查询': [
    {
      'name': 'Qwen3',
      'baseName': 'qwen3',
      'sizes': ['0.6B', '1.7B', '4B', '8B', '14B', '30B', '32B', '235B'],
      'description': '最新一代Qwen模型，支持多语言和法律领域',
    },
    {
      'name': 'ChatGLM3',
      'baseName': 'chatglm3',
      'sizes': ['6B', '12B'],
      'description': '清华大学开发的对话模型',
    },
    {
      'name': 'Baichuan2',
      'baseName': 'baichuan2',
      'sizes': ['7B', '13B'],
      'description': '百川智能开发的中文模型',
    },
  ],
  '合规管理': [
    {
      'name': 'Llama3',
      'baseName': 'llama3',
      'sizes': ['8B', '70B'],
      'description': 'Meta开发的最新Llama模型',
    },
    {
      'name': 'Mistral',
      'baseName': 'mistral',
      'sizes': ['7B', '8x7B', '8x22B'],
      'description': 'Mistral AI开发的高效模型',
    },
  ],
  '通用对话': [
    {
      'name': 'Qwen3',
      'baseName': 'qwen3',
      'sizes': ['0.6B', '1.7B', '4B', '8B', '14B', '30B', '32B', '235B'],
      'description': '最新一代Qwen模型，通用对话能力强',
    },
    {
      'name': 'Llama3',
      'baseName': 'llama3',
      'sizes': ['8B', '70B'],
      'description': 'Meta开发的通用对话模型',
    },
    {
      'name': 'Gemma',
      'baseName': 'gemma',
      'sizes': ['2B', '7B'],
      'description': 'Google开发的轻量级模型',
    },
  ],
  '文档处理': [
    {
      'name': 'Qwen3',
      'baseName': 'qwen3',
      'sizes': ['0.6B', '1.7B', '4B', '8B', '14B', '30B', '32B', '235B'],
      'description': '支持长文档处理的模型',
    },
  ],
  '数据分析': [
    {
      'name': 'DeepSeek-Math',
      'baseName': 'deepseek-math',
      'sizes': ['7B'],
      'description': '专门用于数学和数据分析的模型',
    },
  ],
};

// 在线模型提供商列表
final List<Map<String, dynamic>> onlineProviders = [
  {
    'name': 'Ollama',
    'id': 'ollama',
    'icon': CupertinoIcons.device_laptop,
    'description': '本地运行的开源大语言模型',
    'color': const Color(0xFF22C55E),
    'defaultUrl': 'http://localhost:11434/api',
    'models': [
       {'id': 'qwen3', 'name': 'qwen3', 'specs': '8B • 中英双语 • 代码推理', 'size': ['8b']},

      {'id': 'llama3.2', 'name': 'Llama 3.2', 'specs': '1B-3B • 多模态 • 轻量级', 'size': ['1b', '3b']},
      {'id': 'llama3.1', 'name': 'Llama 3.1', 'specs': '8B-70B • 长上下文 • 高性能', 'size': ['8b', '70b']},
      {'id': 'llama3', 'name': 'Llama 3', 'specs': '8B-70B • 通用对话 • 开源', 'size': ['8b', '70b']},
      {'id': 'llama2', 'name': 'Llama 2', 'specs': '7B-70B • 经典模型 • 稳定', 'size': ['7b', '13b', '70b']},
      {'id': 'codellama', 'name': 'Code Llama', 'specs': '7B-34B • 代码专用 • 编程', 'size': ['7b', '13b', '34b']},
      {'id': 'deepseek-coder-v2', 'name': 'DeepSeek Coder V2', 'specs': '16B-236B • 代码生成 • 多语言', 'size': ['16b', '236b']},
      {'id': 'qwen2.5', 'name': 'Qwen 2.5', 'specs': '0.5B-72B • 中英双语 • 通用', 'size': ['0.5b', '1.5b', '3b', '7b', '14b', '32b', '72b']},
      {'id': 'qwen2.5-coder', 'name': 'Qwen 2.5 Coder', 'specs': '1.5B-32B • 代码专用 • 中英', 'size': ['1.5b', '7b', '14b', '32b']},
      {'id': 'mistral', 'name': 'Mistral', 'specs': '7B • 高效推理 • 欧洲模型', 'size': ['7b']},
      {'id': 'mixtral', 'name': 'Mixtral', 'specs': '8x7B • 专家混合 • 高性能', 'size': ['8x7b', '8x22b']},
      {'id': 'phi3', 'name': 'Phi 3', 'specs': '3.8B-14B • 微软 • 小参数高性能', 'size': ['3.8b', '14b']},
      {'id': 'gemma2', 'name': 'Gemma 2', 'specs': '2B-27B • Google • 开源', 'size': ['2b', '9b', '27b']},
      {'id': 'yi', 'name': 'Yi', 'specs': '6B-34B • 零一万物 • 中英双语', 'size': ['6b', '34b']},
      {'id': 'nomic-embed-text', 'name': 'Nomic Embed Text (嵌入模型)', 'specs': '向量嵌入 • 文本检索 • RAG', 'size': ['text']},
    ],
  },
  {
    'name': 'DeepSeek',
    'id': 'deepseek',
    'icon': CupertinoIcons.cube_box,
    'description': '高性能AI助手，支持多种任务',
    'color': const Color(0xFF3B82F6),
    'defaultUrl': 'https://api.deepseek.com/v1',
    'models': [
      {'id': 'deepseek-chat', 'name': 'DeepSeek-V4-Flash', 'specs': '快速响应 • 高性价比 • 通用对话', },
      {'id': 'deepseek-reasoner', 'name': 'DeepSeek-V4-Pro', 'specs': '深度推理 • 复杂问题 • 思维链',},
    ],
  },
  {
    'name': 'ChatGPT',
    'id': 'openai',
    'icon': CupertinoIcons.command,
    'description': 'OpenAI GPT系列模型',
    'color': const Color(0xFF10B981),
    'defaultUrl': 'https://api.openai.com/v1',
    'models': [
      {'id': 'gpt-4', 'name': 'GPT-4', 'specs': '1.76T参数 • 多模态 • 高级推理', 'size': ['turbo', 'vision']},
      {'id': 'gpt-4-turbo', 'name': 'GPT-4 Turbo', 'specs': '更快响应 • 128K上下文 • 视觉理解', 'size': ['turbo']},
      {'id': 'gpt-3.5-turbo', 'name': 'GPT-3.5 Turbo', 'specs': '175B参数 • 快速响应 • 高性价比', 'size': ['turbo']},
    ],
  },
  {
    'name': 'Claude',
    'id': 'anthropic',
    'icon': CupertinoIcons.device_desktop,
    'description': 'Anthropic Claude系列模型',
    'color': const Color(0xFFF59E0B),
    'defaultUrl': 'https://api.anthropic.com/v1',
    'models': [
      {'id': 'claude-3-opus', 'name': 'Claude 3 Opus', 'specs': '旗舰模型 • 200K上下文 • 复杂推理'},
      {'id': 'claude-3-sonnet', 'name': 'Claude 3 Sonnet', 'specs': '平衡型 • 高质量 • 性价比'},
      {'id': 'claude-3-haiku', 'name': 'Claude 3 Haiku', 'specs': '快速响应 • 轻量级 • 高效'},
    ],
  },
  {
    'name': 'Gemini',
    'id': 'google',
    'icon': CupertinoIcons.person,
    'description': 'Google Gemini系列模型',
    'color': const Color(0xFFEF4444),
    'defaultUrl': 'https://generativelanguage.googleapis.com/v1',
    'models': [
      {'id': 'gemini-pro', 'name': 'Gemini Pro', 'specs': '多模态 • 长上下文 • Google'},
      {'id': 'gemini-pro-vision', 'name': 'Gemini Pro Vision', 'specs': '视觉理解 • 图像分析 • 多模态'},
    ],
  },
  {
    'name': '通义千问',
    'id': 'qwen',
    'icon': CupertinoIcons.chat_bubble_2,
    'description': '阿里巴巴通义千问系列模型',
    'color': const Color(0xFF8B5CF6),
    'defaultUrl': 'https://dashscope.aliyuncs.com/api/v1',
    'models': [
      {'id': 'qwen-turbo', 'name': 'Qwen Turbo', 'specs': '快速响应 • 中英双语 • 高效'},
      {'id': 'qwen-plus', 'name': 'Qwen Plus', 'specs': '平衡型 • 综合能力 • 通用'},
      {'id': 'qwen-max', 'name': 'Qwen Max', 'specs': '旗舰模型 • 最强性能 • 复杂任务'},
    ],
  },
  {
    'name': '智谱AI',
    'id': 'zhipu',
    'icon': CupertinoIcons.lightbulb,
    'description': '智谱AI GLM系列模型',
    'color': const Color(0xFF06B6D4),
    'defaultUrl': 'https://open.bigmodel.cn/api/paas/v4',
    'models': [
      {'id': 'glm-4', 'name': 'GLM-4', 'specs': '通用对话 • 中英双语 • 清华技术'},
      {'id': 'glm-4v', 'name': 'GLM-4V', 'specs': '多模态 • 视觉理解 • 图文对话'},
      {'id': 'glm-3-turbo', 'name': 'GLM-3 Turbo', 'specs': '快速响应 • 高性价比 • 轻量级'},
    ],
  },
  {
    'name': '魔塔社区',
    'id': 'modelscope',
    'icon': CupertinoIcons.device_desktop,
    'description': 'ModelScope社区模型，兼容OpenAI API',
    'color': const Color(0xFF9333EA),
    'defaultUrl': 'https://api-inference.modelscope.cn/v1/',
    'models': [
      {'id': 'qwen2.5-72b-instruct', 'name': 'Qwen2.5-72B-Instruct', 'specs': '72B参数 • 旗舰模型 • 强推理'},
      {'id': 'qwen2.5-32b-instruct', 'name': 'Qwen2.5-32B-Instruct', 'specs': '32B参数 • 平衡型 • 高性能'},
      {'id': 'qwen2.5-14b-instruct', 'name': 'Qwen2.5-14B-Instruct', 'specs': '14B参数 • 中等规模 • 通用'},
      {'id': 'qwen2.5-7b-instruct', 'name': 'Qwen2.5-7B-Instruct', 'specs': '7B参数 • 轻量级 • 快速'},
      {'id': 'qwen2.5-coder-32b-instruct', 'name': 'Qwen2.5-Coder-32B', 'specs': '32B参数 • 代码专用 • 编程'},
      {'id': 'qwen2.5-coder-14b-instruct', 'name': 'Qwen2.5-Coder-14B', 'specs': '14B参数 • 代码生成 • 调试'},
      {'id': 'qwen2.5-coder-7b-instruct', 'name': 'Qwen2.5-Coder-7B', 'specs': '7B参数 • 代码辅助 • 轻量'},
      {'id': 'baichuan2-13b-chat', 'name': 'Baichuan2-13B-Chat', 'specs': '13B参数 • 中文优化 • 对话'},
      {'id': 'baichuan2-7b-chat', 'name': 'Baichuan2-7B-Chat', 'specs': '7B参数 • 中文模型 • 高效'},
      {'id': 'chatglm3-6b', 'name': 'ChatGLM3-6B', 'specs': '6B参数 • 清华技术 • 中英双语'},
      {'id': 'yi-34b-chat', 'name': 'Yi-34B-Chat', 'specs': '34B参数 • 零一万物 • 强对话'},
      {'id': 'yi-6b-chat', 'name': 'Yi-6B-Chat', 'specs': '6B参数 • 轻量级 • 中英双语'},
    ],
  },
  
];
