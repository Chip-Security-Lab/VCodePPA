//SystemVerilog
//===================================================================
// Module: glitch_filter_recovery (Top level)
// Standard: IEEE 1364-2005
// Description: Signal glitch filtering with hierarchical structure
//===================================================================
module glitch_filter_recovery (
    input  wire clk,
    input  wire rst_n,
    input  wire noisy_input,
    output wire clean_output
);
    // Internal signals
    wire [3:0] filtered_pattern;
    wire       decision_out;
    
    // Instantiate shift register module
    shift_register_unit u_shift_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_in      (noisy_input),
        .pattern_out  (filtered_pattern)
    );
    
    // Instantiate pattern detection and decision module
    pattern_detector u_pattern_detect (
        .clk          (clk),
        .rst_n        (rst_n),
        .pattern_in   (filtered_pattern),
        .clean_signal (decision_out)
    );
    
    // Instantiate output register module
    output_register u_out_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .decision_in  (decision_out),
        .clean_out    (clean_output)
    );
    
endmodule

//===================================================================
// Module: shift_register_unit
// Standard: IEEE 1364-2005
// Description: 4-bit shift register for input signal
//===================================================================
module shift_register_unit #(
    parameter BIT_WIDTH = 4
) (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output reg [BIT_WIDTH-1:0] pattern_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_out <= {BIT_WIDTH{1'b0}};
        end else begin
            pattern_out <= {pattern_out[BIT_WIDTH-2:0], data_in};
        end
    end
    
endmodule

//===================================================================
// Module: pattern_detector
// Standard: IEEE 1364-2005
// Description: Detects stable patterns from shift register data
//===================================================================
module pattern_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] pattern_in,
    output reg  clean_signal
);
    
    // 跳跃进位加法器/进位前瞻加法器实现计数功能
    function [2:0] count_ones;
        input [3:0] pattern;
        reg [2:0] sum;
        reg [3:0] p, g; // 生成(generate)和传播(propagate)信号
        reg [3:0] c;    // 进位信号
        begin
            // 初始化生成和传播信号
            p = pattern;
            g = 4'b0000; // 对于单比特加法，没有内部生成
            
            // 计算进位信号 - 跳跃进位加法器逻辑
            c[0] = 1'b0; // 初始进位为0
            c[1] = g[0] | (p[0] & c[0]);
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
            
            // 计算最终和
            sum[0] = p[0] ^ c[0];
            sum[1] = p[1] ^ c[1];
            sum[2] = p[2] ^ c[2] | (p[3] ^ c[3]); // 合并第4位到总和中
            
            count_ones = sum;
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_signal <= 1'b0;
        end else begin
            // Decision logic: if 3 or more bits are 1, output 1
            // if 3 or more bits are 0, output 0
            // otherwise maintain previous value
            if (count_ones(pattern_in) >= 3) begin
                clean_signal <= 1'b1;
            end else if (count_ones(pattern_in) <= 1) begin
                clean_signal <= 1'b0;
            end
            // else maintain current value (implicit)
        end
    end
    
endmodule

//===================================================================
// Module: output_register
// Standard: IEEE 1364-2005
// Description: Registers the clean output signal
//===================================================================
module output_register (
    input  wire clk,
    input  wire rst_n,
    input  wire decision_in,
    output reg  clean_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_out <= 1'b0;
        end else begin
            clean_out <= decision_in;
        end
    end
    
endmodule