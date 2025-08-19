//SystemVerilog
module pipo_reg #(parameter DATA_WIDTH = 8) (
    input wire clock, reset, enable,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    // 流水线控制信号
    input wire valid_in,
    output reg valid_out,
    input wire ready_in,
    output wire ready_out
);
    // 流水线寄存器和控制信号
    reg [DATA_WIDTH-1:0] stage1_data;
    reg [DATA_WIDTH-1:0] stage2_data;
    reg stage1_valid, stage2_valid;
    wire stage1_ready, stage2_ready;
    
    // 高扇出信号缓冲
    reg [2:0] enable_buf;
    reg [1:0] stage1_ready_buf;
    reg [1:0] stage2_ready_buf;
    
    // 控制信号缓冲寄存器
    always @(posedge clock) begin
        if (reset) begin
            enable_buf <= 3'b0;
            stage1_ready_buf <= 2'b0;
            stage2_ready_buf <= 2'b0;
        end
        else begin
            enable_buf <= {3{enable}};
            stage1_ready_buf <= {2{stage1_ready}};
            stage2_ready_buf <= {2{stage2_ready}};
        end
    end
    
    // 流水线控制逻辑
    wire b0, b1, b2;
    assign b0 = ~stage1_valid;
    assign b1 = ~stage2_valid;
    
    // 高扇出信号b0的缓冲
    reg [1:0] b0_buf;
    always @(posedge clock) begin
        if (reset)
            b0_buf <= 2'b0;
        else
            b0_buf <= {2{b0}};
    end
    
    assign ready_out = b0_buf[0] | stage1_ready_buf[0];
    assign stage1_ready = b1 | stage2_ready;
    assign stage2_ready = ready_in;
    
    // 第一级流水线
    always @(posedge clock) begin
        if (reset) begin
            stage1_data <= {DATA_WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end
        else if (enable_buf[0] && ready_out && valid_in) begin
            stage1_data <= data_in;
            stage1_valid <= 1'b1;
        end
        else if (stage1_ready_buf[0] && enable_buf[0]) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 第二级流水线
    always @(posedge clock) begin
        if (reset) begin
            stage2_data <= {DATA_WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end
        else if (enable_buf[1] && stage1_ready_buf[1] && stage1_valid) begin
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
        else if (stage2_ready_buf[0] && enable_buf[1]) begin
            stage2_valid <= 1'b0;
        end
    end
    
    // 输出级流水线
    always @(posedge clock) begin
        if (reset) begin
            data_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else if (enable_buf[2] && stage2_ready_buf[1] && stage2_valid) begin
            data_out <= stage2_data;
            valid_out <= stage2_valid;
        end
        else if (ready_in && enable_buf[2]) begin
            valid_out <= 1'b0;
        end
    end
endmodule