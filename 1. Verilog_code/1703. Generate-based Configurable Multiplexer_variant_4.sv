//SystemVerilog
module generate_mux #(
    parameter NUM_INPUTS = 16,
    parameter DATA_WIDTH = 8
)(
    input [DATA_WIDTH-1:0] data_in [0:NUM_INPUTS-1],
    input [$clog2(NUM_INPUTS)-1:0] sel,
    input clk,
    input rst_n,
    output reg [DATA_WIDTH-1:0] data_out
);
    // 第一阶段：选择器解码
    reg [$clog2(NUM_INPUTS)-1:0] sel_pipe1;
    reg [NUM_INPUTS-1:0] sel_onehot;
    
    // 第二阶段：数据选择
    reg [DATA_WIDTH-1:0] selected_data;
    
    // 选择器流水线 - 阶段1：寄存器选择器和创建独热编码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_pipe1 <= {$clog2(NUM_INPUTS){1'b0}};
            sel_onehot <= {NUM_INPUTS{1'b0}};
        end else begin
            sel_pipe1 <= sel;
            sel_onehot <= 1'b1 << sel;
        end
    end
    
    // 数据选择逻辑 - 阶段2：使用独热编码直接选择数据
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_data <= {DATA_WIDTH{1'b0}};
        end else begin
            selected_data <= {DATA_WIDTH{1'b0}};
            for (k = 0; k < NUM_INPUTS; k = k + 1) begin
                if (sel_onehot[k]) begin
                    selected_data <= data_in[k];
                end
            end
        end
    end
    
    // 输出寄存器 - 阶段3：稳定输出数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out <= selected_data;
        end
    end
endmodule