"""PPA评分和相关工具函数"""
import math


def calculate_ppa_score(ppa_metrics, design_type='auto'):
    """
    计算综合PPA评分，考虑不同设计类型和指标间的复杂关系

    Args:
        ppa_metrics: PPA指标字典
        design_type: 设计类型 ('combinational', 'sequential', 或 'auto')

    Returns:
        dict: 包含总分和分项分数的字典
    """
    # 确定设计类型
    if design_type == 'auto':
        # 如果有FF且数量>0，视为时序逻辑，否则为组合逻辑
        has_ff = 'ff' in ppa_metrics and ppa_metrics['ff'] > 0

        if has_ff:
            design_type = 'sequential'
        else:
            design_type = 'combinational'

    # 初始化分数
    scores = {
        'area_score': 0.0,
        'performance_score': 0.0,
        'power_score': 0.0,
        'total_score': 0.0
    }

    # 1. 面积评分计算 (0-100分，越高越好)
    area_score = 0.0
    area_metrics_count = 0

    # LUT评分 - 考虑非线性关系
    if 'lut' in ppa_metrics:
        lut_count = ppa_metrics['lut']
        # 小型设计(LUT<10)中LUT减少1个影响大，大型设计中影响较小
        if lut_count < 10:
            lut_score = 100 * (1.0 - (lut_count / 10.0))
        elif lut_count < 100:
            lut_score = 90 * (1.0 - (lut_count - 10) / 90.0)
        else:
            lut_score = 50 * (1.0 - min(1.0, (lut_count - 100) / 900.0))

        area_score += lut_score
        area_metrics_count += 1

    # FF评分
    if 'ff' in ppa_metrics:
        ff_count = ppa_metrics['ff']
        # 时序设计中，适量FF是必要的，仅惩罚过多FF
        if design_type == 'sequential':
            # 对于时序逻辑，使用更加宽容的FF评分
            if ff_count < 20:
                ff_score = 100
            elif ff_count < 100:
                ff_score = 90 * (1.0 - (ff_count - 20) / 80.0)
            else:
                ff_score = 50 * (1.0 - min(1.0, (ff_count - 100) / 900.0))
        else:
            # 组合逻辑中应当尽量避免FF
            ff_score = 100 * (1.0 - min(1.0, ff_count / 10.0))

        area_score += ff_score
        area_metrics_count += 1

    # IO评分 - IO通常由接口决定，影响较小
    if 'io' in ppa_metrics:
        io_count = ppa_metrics['io']
        io_score = 100 * (1.0 - min(1.0, io_count / 100.0))
        # IO权重较低，仅占0.5份
        area_score += io_score * 0.5
        area_metrics_count += 0.5

    # Cell Count评分
    if 'cell_count' in ppa_metrics:
        cell_count = ppa_metrics['cell_count']
        if cell_count < 50:
            cell_score = 100 * (1.0 - (cell_count / 50.0))
        elif cell_count < 500:
            cell_score = 90 * (1.0 - (cell_count - 50) / 450.0)
        else:
            cell_score = 50 * (1.0 - min(1.0, (cell_count - 500) / 4500.0))

        area_score += cell_score
        area_metrics_count += 1

    # 计算面积平均分
    if area_metrics_count > 0:
        area_score /= area_metrics_count
        scores['area_score'] = area_score

    # 2. 性能评分计算 (0-100分，越高越好)
    performance_score = 0.0
    performance_metrics_count = 0

    # 最大频率评分
    if 'max_freq' in ppa_metrics and ppa_metrics['max_freq'] != "N/A":
        max_freq = ppa_metrics['max_freq']
        # 频率越高越好，非线性映射
        if max_freq < 100:
            freq_score = 50 * (max_freq / 100.0)
        elif max_freq < 500:
            freq_score = 50 + 40 * ((max_freq - 100) / 400.0)
        else:
            freq_score = 90 + 10 * min(1.0, (max_freq - 500) / 500.0)

        performance_score += freq_score
        performance_metrics_count += 1

    # 寄存器到寄存器延迟评分
    if 'reg_to_reg_delay' in ppa_metrics and design_type == 'sequential':
        reg_delay = ppa_metrics['reg_to_reg_delay']
        # 延迟越低越好，使用指数衰减
        reg_delay_score = 100 * math.exp(-reg_delay / 2.0)

        performance_score += reg_delay_score
        performance_metrics_count += 1

    # 端到端延迟评分
    if 'end_to_end_delay' in ppa_metrics:
        end_delay = ppa_metrics['end_to_end_delay']
        # 延迟越低越好，使用指数衰减
        if design_type == 'combinational':
            # 组合逻辑中，端到端延迟更重要
            end_delay_score = 100 * math.exp(-end_delay / 5.0)
            performance_score += end_delay_score
            performance_metrics_count += 1
        else:
            # 时序逻辑中，如果没有reg_to_reg_delay，才计入端到端延迟
            if 'reg_to_reg_delay' not in ppa_metrics:
                end_delay_score = 100 * math.exp(-end_delay / 5.0)
                performance_score += end_delay_score
                performance_metrics_count += 1

    # 计算性能平均分
    if performance_metrics_count > 0:
        performance_score /= performance_metrics_count
        scores['performance_score'] = performance_score

    # 3. 功耗评分计算 (0-100分，越高越好)
    power_score = 0.0

    if 'total_power' in ppa_metrics:
        power = ppa_metrics['total_power']

        # 考虑复杂度调整功耗评分
        complexity_factor = 1.0
        if 'cell_count' in ppa_metrics:
            # 复杂设计功耗自然较高，调整评分标准
            cell_count = ppa_metrics['cell_count']
            if cell_count > 100:
                complexity_factor = math.log10(cell_count) / 2.0

        # 考虑时钟频率调整功耗评分
        freq_factor = 1.0
        if 'max_freq' in ppa_metrics and ppa_metrics['max_freq'] != "N/A":
            max_freq = ppa_metrics['max_freq']
            if max_freq > 100:
                freq_factor = (max_freq / 100.0) ** 0.5

        # 功耗归一化
        adjusted_power = power / (complexity_factor * freq_factor)

        # 功耗评分 - 功耗越低越好
        if adjusted_power < 0.1:
            power_score = 100
        elif adjusted_power < 1.0:
            power_score = 90 - 40 * (adjusted_power - 0.1) / 0.9
        elif adjusted_power < 5.0:
            power_score = 50 - 30 * (adjusted_power - 1.0) / 4.0
        else:
            power_score = 20 * math.exp(-(adjusted_power - 5.0) / 5.0)

        scores['power_score'] = power_score

    # 4. 计算总分，根据设计类型和应用场景调整权重
    if design_type == 'combinational':
        # 组合逻辑通常优先考虑面积和延迟
        area_weight = 0.40
        performance_weight = 0.45
        power_weight = 0.15
    else:  # sequential
        # 时序逻辑通常更看重性能和功耗平衡
        area_weight = 0.30
        performance_weight = 0.45
        power_weight = 0.25

    # 计算总加权分数
    total_score = 0.0
    weights_sum = 0.0

    if 'area_score' in scores:
        total_score += area_weight * scores['area_score']
        weights_sum += area_weight

    if 'performance_score' in scores:
        total_score += performance_weight * scores['performance_score']
        weights_sum += performance_weight

    if 'power_score' in scores:
        total_score += power_weight * scores['power_score']
        weights_sum += power_weight

    if weights_sum > 0:
        total_score /= weights_sum

    scores['total_score'] = total_score
    scores['design_type'] = design_type

    return scores