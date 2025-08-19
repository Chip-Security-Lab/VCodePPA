# vivado_synth.tcl
# 用于Verilog代码综合、实现和PPA报告生成的TCL脚本
#
# 参数:
# - argv[0]: Verilog文件路径
# - argv[1]: 模块名
# - argv[2]: FPGA型号
# - argv[3]: 工作目录

# 提取命令行参数
if {$argc < 4} {
    puts "错误: 需要4个参数: <verilog_file> <module_name> <fpga_part> <work_dir>"
    exit 1
}

set verilog_file [lindex $argv 0]
set module_name [lindex $argv 1]
set fpga_part [lindex $argv 2]
set work_dir [lindex $argv 3]

# 打印参数
puts "Verilog文件: $verilog_file"
puts "模块名: $module_name"
puts "FPGA型号: $fpga_part"
puts "工作目录: $work_dir"

# 设置输出文件路径
set utilization_rpt "$work_dir/utilization.rpt"
set timing_rpt "$work_dir/timing.rpt"
set power_rpt "$work_dir/power.rpt"
set ppa_report "$work_dir/${module_name}_ppa_report.txt"

# 创建工程
set proj_dir "$work_dir/${module_name}_proj"
puts "创建工程: $proj_dir"

# 创建工程，如果已存在则先删除
file mkdir $proj_dir
create_project -force ${module_name}_proj $proj_dir -part $fpga_part

# 添加源文件
add_files -norecurse $verilog_file
update_compile_order -fileset sources_1

# 设置顶层模块
set_property top $module_name [current_fileset]
set_property source_mgmt_mode None [current_project]
update_compile_order -fileset sources_1

# 检测时钟信号，设置时钟约束
set fd [open $verilog_file r]
set file_data [read $fd]
close $fd

# 尝试从文件中检测时钟信号
set has_clock_input [regexp -nocase {input\s+(?:wire\s+)?(?:\[[^\]]+\]\s+)?(?:reg\s+)?(?:\s*)clk\s*[,;\)]} $file_data]
set has_clock_posedge [regexp -nocase {always\s+@\s*\(\s*posedge\s+clk} $file_data]
set has_clock [expr {$has_clock_input || $has_clock_posedge}]

# 查找可能的时钟端口名称
set possible_clock_names {clk clock CLK CLOCK clk_i clock_i CLK_I CLOCK_I clk_in clock_in sys_clk sys_clock}
set clock_port ""

foreach clk_name $possible_clock_names {
    if {[regexp -nocase "input\[^;\]*\\b${clk_name}\\b" $file_data]} {
        set has_clock 1
        set clock_port $clk_name
        break
    }
}

# 创建约束文件
file mkdir [file join $proj_dir "constraints"]
set xdc_file [file join $proj_dir "constraints" "constraints.xdc"]
set xdc_fd [open $xdc_file w]

if {$has_clock} {
    puts "检测到时钟端口: $clock_port"
    puts $xdc_fd "# 时钟约束"
    puts $xdc_fd "create_clock -period 10.000 -name clk -waveform {0.000 5.000} \[get_ports $clock_port\]"
    puts $xdc_fd "set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN \[get_nets $clock_port\]"
    puts $xdc_fd "set_clock_uncertainty 0.100 \[get_clocks clk\]"
} else {
    puts "没有检测到时钟端口，使用虚拟时钟"
    puts $xdc_fd "# 虚拟时钟约束"
    puts $xdc_fd "create_clock -period 10.000 -name virtual_clock"
    puts $xdc_fd "set_input_delay -clock virtual_clock 0.000 \[get_ports -filter {DIRECTION == IN}\]"
    puts $xdc_fd "set_output_delay -clock virtual_clock 0.000 \[get_ports -filter {DIRECTION == OUT}\]"
}

close $xdc_fd

# 添加约束文件
add_files -fileset constrs_1 $xdc_file
set_property used_in_synthesis true [get_files $xdc_file]
set_property used_in_implementation true [get_files $xdc_file]

# 初始化PPA指标变量
set lut_count "N/A"
set ff_count "N/A"
set io_count "N/A"
set utilization_percent "N/A"
set max_freq "N/A (Combinational logic)"
set longest_path "N/A"
set total_power "N/A"
set dynamic_power "N/A"
set static_power "N/A"

# 运行综合
puts "开始综合..."
reset_run synth_1
launch_runs synth_1 -jobs 4

# 等待综合完成，最多15分钟
set timeout_seconds 900
set start_time [clock seconds]
set completed 0

while {!$completed} {
    # 检查综合是否完成
    if {[get_property PROGRESS [get_runs synth_1]] == "100%"} {
        set completed 1
    }

    # 检查超时
    set current_time [clock seconds]
    if {[expr {$current_time - $start_time}] > $timeout_seconds} {
        puts "警告: 综合超时，超过 $timeout_seconds 秒"
        break
    }

    # 避免CPU过载
    after 5000
}

# 检查综合是否成功
if {[get_property PROGRESS [get_runs synth_1]] == "100%" &&
    [get_property STATUS [get_runs synth_1]] == "synth_design Complete!"} {

    puts "综合完成"

    # 打开综合结果
    open_run synth_1 -name synth_1

    # 生成资源利用率报告
    report_utilization -file $utilization_rpt

    # 提取资源使用情况
    set util_file [open $utilization_rpt r]
    set utilization_data [read $util_file]
    close $util_file

    # 提取LUT使用量
    if {[regexp {CLB LUTs\*?\s*\|\s*(\d+)} $utilization_data match lut_val]} {
        set lut_count $lut_val
    } elseif {[regexp {LUT as Logic\s*\|\s*(\d+)} $utilization_data match lut_val]} {
        set lut_count $lut_val
    }

    # 提取FF使用量
    if {[regexp {CLB Registers\s*\|\s*(\d+)} $utilization_data match ff_val]} {
        set ff_count $ff_val
    } elseif {[regexp {Register as Flip Flop\s*\|\s*(\d+)} $utilization_data match ff_val]} {
        set ff_count $ff_val
    }

    # 提取IO使用量
    if {[regexp {I/O\s*\|\s*(\d+)} $utilization_data match io_val]} {
        set io_count $io_val
    } elseif {[regexp {Bonded IOB\s*\|\s*(\d+)} $utilization_data match io_val]} {
        set io_count $io_val
    }

    # 提取利用率百分比
    if {[regexp {CLB\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*(\d+\.\d+)} $utilization_data match util_percent]} {
        set utilization_percent $util_percent
    } elseif {[regexp {CLB LUTs\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*(\d+\.\d+)} $utilization_data match util_percent]} {
        set utilization_percent $util_percent
    } elseif {[regexp {Slice LUTs\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*(\d+\.\d+)} $utilization_data match util_percent]} {
        set utilization_percent $util_percent
    } elseif {[regexp {LUT as Logic\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*(\d+\.\d+)} $utilization_data match util_percent]} {
        set utilization_percent $util_percent
    } else {
        # 如果无法提取，使用一个近似值计算
        if {$lut_count != "N/A" && [string is integer -strict $lut_count]} {
            # xcku3p大约有163,000个LUT
            set total_luts 163000
            set utilization_percent [format "%.4f" [expr {double($lut_count) / $total_luts * 100}]]
        }
    }

    # 生成时序报告
    report_timing_summary -file $timing_rpt

    # 如果是时序设计，提取时序信息
    if {$has_clock} {
        # 尝试提取WNS（最差负裕量）
        set timing_file [open $timing_rpt r]
        set timing_data [read $timing_file]
        close $timing_file

        # 查找WNS
        if {[regexp {WNS(?:\(ns\))?\s*\|?\s*(-?\d+\.\d+)} $timing_data match wns]} {
            # 从WNS计算最大频率
            set period 10.000
            set slack [expr double($wns)]

            # 如果slack为正，则满足时序约束
            if {$slack >= 0} {
                set max_freq [format "%.2f" [expr {1000.0 / $period}]]
            } else {
                # 如果slack为负，则计算实际可达最大频率
                set actual_period [expr {$period - $slack}]
                set max_freq [format "%.2f" [expr {1000.0 / $actual_period}]]
            }

            # 提取关键路径延迟
            if {[regexp {data path delay:\s+(\d+\.\d+)} $timing_data match path_delay]} {
                set longest_path $path_delay
            } elseif {[regexp {Data Path Delay:\s+(\d+\.\d+)} $timing_data match path_delay]} {
                set longest_path $path_delay
            } else {
                # 尝试直接获取时序路径
                if {[catch {
                    set timing_paths [get_timing_paths -max_paths 1 -nworst 1 -setup]
                    if {[llength $timing_paths] > 0} {
                        set path_delay [get_property DATAPATH_DELAY $timing_paths]
                        set longest_path [format "%.3f" $path_delay]
                    }
                } result]} {
                    puts "警告：无法获取路径延迟: $result"
                }
            }
        }
    } else {
        # 组合逻辑，查找输入到输出的延迟
        if {[catch {
            set timing_paths [get_timing_paths -from [all_inputs] -to [all_outputs] -max_paths 1 -nworst 1]
            if {[llength $timing_paths] > 0} {
                set path_delay [get_property DATAPATH_DELAY $timing_paths]
                set longest_path [format "%.3f" $path_delay]
            }
        } result]} {
            puts "警告：无法获取组合路径延迟: $result"
        }
    }

    # 运行实现
    puts "开始实现..."
    reset_run impl_1
    launch_runs impl_1 -jobs 4

    # 等待实现完成，最多20分钟
    set timeout_seconds 1200
    set start_time [clock seconds]
    set completed 0

    while {!$completed} {
        # 检查实现是否完成
        if {[get_property PROGRESS [get_runs impl_1]] == "100%"} {
            set completed 1
        }

        # 检查超时
        set current_time [clock seconds]
        if {[expr {$current_time - $start_time}] > $timeout_seconds} {
            puts "警告: 实现超时，超过 $timeout_seconds 秒"
            break
        }

        # 避免CPU过载
        after 5000
    }

    # 检查实现是否成功
    if {[get_property PROGRESS [get_runs impl_1]] == "100%" &&
        [get_property STATUS [get_runs impl_1]] != "Route Design ERROR"} {

        puts "实现完成"

        # 打开实现结果
        open_run impl_1

        # 生成功耗报告
        report_power -file $power_rpt

        # 提取功耗数据
        set power_file [open $power_rpt r]
        set power_data [read $power_file]
        close $power_file

        # 提取总功耗
        if {[regexp {Total On-Chip Power \(W\)\s*\|\s*(\d+\.\d+)} $power_data match power_val]} {
            set total_power $power_val
        }

        # 提取动态功耗
        if {[regexp {Dynamic \(W\)\s*\|\s*(\d+\.\d+)} $power_data match dynamic_val]} {
            set dynamic_power $dynamic_val
        }

        # 提取静态功耗
        if {[regexp {Device Static \(W\)\s*\|\s*(\d+\.\d+)} $power_data match static_val]} {
            set static_power $static_val
        }

        # 如果是时序设计，再次提取时序信息（可能更准确）
        if {$has_clock} {
            report_timing_summary -file "${work_dir}/impl_timing.rpt"

            set timing_file [open "${work_dir}/impl_timing.rpt" r]
            set timing_data [read $timing_file]
            close $timing_file

            # 查找WNS
            if {[regexp {WNS(?:\(ns\))?\s*\|?\s*(-?\d+\.\d+)} $timing_data match wns]} {
                # 从WNS计算最大频率
                set period 10.000
                set slack [expr double($wns)]

                # 如果slack为正，则满足时序约束
                if {$slack >= 0} {
                    set max_freq [format "%.2f" [expr {1000.0 / $period}]]
                } else {
                    # 如果slack为负，则计算实际可达最大频率
                    set actual_period [expr {$period - $slack}]
                    set max_freq [format "%.2f" [expr {1000.0 / $actual_period}]]
                }

                # 提取关键路径延迟
                if {[regexp {data path delay:\s+(\d+\.\d+)} $timing_data match path_delay]} {
                    set longest_path $path_delay
                } elseif {[regexp {Data Path Delay:\s+(\d+\.\d+)} $timing_data match path_delay]} {
                    set longest_path $path_delay
                } else {
                    # 尝试直接获取时序路径
                    if {[catch {
                        set timing_paths [get_timing_paths -max_paths 1 -nworst 1 -setup]
                        if {[llength $timing_paths] > 0} {
                            set path_delay [get_property DATAPATH_DELAY $timing_paths]
                            set longest_path [format "%.3f" $path_delay]
                        }
                    } result]} {
                        puts "警告：无法获取实现后的路径延迟: $result"
                    }
                }
            }
        }
    } else {
        puts "实现失败或未完成"
    }
} else {
    puts "综合失败或未完成"
}

# 生成PPA报告文件
puts "生成PPA报告: $ppa_report"
set ppa_fd [open $ppa_report w]

puts $ppa_fd "PPA Report for ${module_name}.v (Module: ${module_name})"
puts $ppa_fd "=========================================="
puts $ppa_fd ""
puts $ppa_fd "FPGA Device: $fpga_part (UltraScale+ 16nm Technology)"
puts $ppa_fd ""

puts $ppa_fd "AREA METRICS:"
puts $ppa_fd "------------"
puts $ppa_fd "LUT Count: $lut_count"
puts $ppa_fd "FF Count: $ff_count"
puts $ppa_fd "IO Count: $io_count"
puts $ppa_fd "Resource Utilization: $utilization_percent%"
puts $ppa_fd ""

puts $ppa_fd "PERFORMANCE METRICS:"
puts $ppa_fd "-------------------"
if {$has_clock} {
    puts $ppa_fd "Maximum Clock Frequency: $max_freq MHz"
} else {
    puts $ppa_fd "Maximum Clock Frequency: $max_freq"
}
puts $ppa_fd "Longest Path Delay: $longest_path ns"
puts $ppa_fd ""

puts $ppa_fd "POWER METRICS:"
puts $ppa_fd "-------------"
puts $ppa_fd "Total Power Consumption: $total_power W"
if {$dynamic_power != "N/A"} {
    puts $ppa_fd "Dynamic Power: $dynamic_power W"
}
if {$static_power != "N/A"} {
    puts $ppa_fd "Static Power: $static_power W"
}

close $ppa_fd

puts "PPA报告生成完成: $ppa_report"

# 清理
catch {close_design}
catch {close_project}

puts "处理完成"
exit 0