//SystemVerilog
module ITRC_MemoryMapped #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] wr_data,
    input wr_en,
    output reg [DATA_WIDTH-1:0] rd_data,
    input [DATA_WIDTH-1:0] int_status
);

    reg [DATA_WIDTH-1:0] int_reg;
    reg [DATA_WIDTH-1:0] int_reg_pipe;
    wire [DATA_WIDTH-1:0] next_int_reg;
    
    // 二进制补码计算流水线
    reg [DATA_WIDTH-1:0] wr_data_comp_pipe;
    reg [DATA_WIDTH-1:0] int_status_comp_pipe;
    reg wr_en_pipe;
    
    wire [DATA_WIDTH-1:0] wr_data_comp = ~wr_data + 1'b1;
    wire [DATA_WIDTH-1:0] int_status_comp = ~int_status + 1'b1;
    
    // 减法器流水线
    reg [DATA_WIDTH-1:0] sub_result_pipe;
    wire [DATA_WIDTH-1:0] sub_result = wr_en_pipe ? (int_reg_pipe + wr_data_comp_pipe) : (int_reg_pipe + int_status_comp_pipe);
    
    // 寄存器更新逻辑
    assign next_int_reg = !rst_n ? {DATA_WIDTH{1'b0}} : sub_result_pipe;
    
    // 流水线寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_data_comp_pipe <= {DATA_WIDTH{1'b0}};
            int_status_comp_pipe <= {DATA_WIDTH{1'b0}};
            wr_en_pipe <= 1'b0;
            int_reg_pipe <= {DATA_WIDTH{1'b0}};
            sub_result_pipe <= {DATA_WIDTH{1'b0}};
        end else begin
            wr_data_comp_pipe <= wr_data_comp;
            int_status_comp_pipe <= int_status_comp;
            wr_en_pipe <= wr_en;
            int_reg_pipe <= int_reg;
            sub_result_pipe <= sub_result;
        end
    end
    
    always @(posedge clk) begin
        int_reg <= next_int_reg;
    end
    
    always @* begin
        rd_data = int_reg;
    end
endmodule