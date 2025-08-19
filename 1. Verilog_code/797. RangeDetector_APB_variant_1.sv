//SystemVerilog
module RangeDetector_APB #(
    parameter WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input psel, penable, pwrite,
    input [ADDR_WIDTH-1:0] paddr,
    input [WIDTH-1:0] pwdata,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] prdata,
    output reg out_range
);
    // 定义阈值寄存器
    reg [WIDTH-1:0] threshold_lower;
    reg [WIDTH-1:0] threshold_upper;
    
    // 范围检测结果预计算寄存器
    reg range_status;
    
    // 条件求和减法器信号
    wire [WIDTH-1:0] diff_lower, diff_upper;
    wire lower_borrow, upper_borrow;
    wire [3:0] lower_a, lower_b, upper_a, upper_b;
    wire [3:0] lower_diff, upper_diff;
    
    // APB写操作处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_lower <= 0;
            threshold_upper <= {WIDTH{1'b1}};
        end
        else if (psel && penable && pwrite) begin
            case(paddr[0])
                1'b0: threshold_lower <= pwdata;
                1'b1: threshold_upper <= pwdata;
            endcase
        end
    end
    
    // 4位条件求和减法器实现 - 用于下界比较
    assign lower_a = data_in[3:0];
    assign lower_b = threshold_lower[3:0];
    
    // 条件求和减法算法实现
    assign lower_diff[0] = lower_a[0] ^ lower_b[0];
    assign lower_diff[1] = lower_a[1] ^ lower_b[1] ^ (lower_a[0] < lower_b[0]);
    assign lower_diff[2] = lower_a[2] ^ lower_b[2] ^ ((lower_a[1] < lower_b[1]) || 
                                                    (lower_a[1] == lower_b[1] && lower_a[0] < lower_b[0]));
    assign lower_diff[3] = lower_a[3] ^ lower_b[3] ^ ((lower_a[2] < lower_b[2]) || 
                                                    (lower_a[2] == lower_b[2] && lower_a[1] < lower_b[1]) ||
                                                    (lower_a[2] == lower_b[2] && lower_a[1] == lower_b[1] && lower_a[0] < lower_b[0]));
    
    assign lower_borrow = (lower_a[3] < lower_b[3]) || 
                          (lower_a[3] == lower_b[3] && lower_a[2] < lower_b[2]) ||
                          (lower_a[3] == lower_b[3] && lower_a[2] == lower_b[2] && lower_a[1] < lower_b[1]) ||
                          (lower_a[3] == lower_b[3] && lower_a[2] == lower_b[2] && lower_a[1] == lower_b[1] && lower_a[0] < lower_b[0]);
    
    // 4位条件求和减法器实现 - 用于上界比较
    assign upper_a = threshold_upper[3:0];
    assign upper_b = data_in[3:0];
    
    // 条件求和减法算法实现
    assign upper_diff[0] = upper_a[0] ^ upper_b[0];
    assign upper_diff[1] = upper_a[1] ^ upper_b[1] ^ (upper_a[0] < upper_b[0]);
    assign upper_diff[2] = upper_a[2] ^ upper_b[2] ^ ((upper_a[1] < upper_b[1]) || 
                                                    (upper_a[1] == upper_b[1] && upper_a[0] < upper_b[0]));
    assign upper_diff[3] = upper_a[3] ^ upper_b[3] ^ ((upper_a[2] < upper_b[2]) || 
                                                    (upper_a[2] == upper_b[2] && upper_a[1] < upper_b[1]) ||
                                                    (upper_a[2] == upper_b[2] && upper_a[1] == upper_b[1] && upper_a[0] < upper_b[0]));
    
    assign upper_borrow = (upper_a[3] < upper_b[3]) || 
                          (upper_a[3] == upper_b[3] && upper_a[2] < upper_b[2]) ||
                          (upper_a[3] == upper_b[3] && upper_a[2] == upper_b[2] && upper_a[1] < upper_b[1]) ||
                          (upper_a[3] == upper_b[3] && upper_a[2] == upper_b[2] && upper_a[1] == upper_b[1] && upper_a[0] < upper_b[0]);
    
    // 预计算范围检测结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_status <= 1'b0;
        end
        else begin
            range_status <= (!lower_borrow) || upper_borrow;
        end
    end
    
    // 输出寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_range <= 1'b0;
            prdata <= 0;
        end
        else begin
            out_range <= range_status;
            prdata <= paddr[0] ? threshold_upper : threshold_lower;
        end
    end
endmodule