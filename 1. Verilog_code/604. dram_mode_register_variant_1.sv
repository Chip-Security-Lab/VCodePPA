//SystemVerilog
module dram_mode_register #(
    parameter MR_ADDR_WIDTH = 4
)(
    input clk,
    input rst_n,
    input load_mr,
    input [MR_ADDR_WIDTH-1:0] mr_addr,
    input [15:0] mr_data,
    output [15:0] current_mode
);

    // Mode Register Storage Module
    mode_register_storage #(
        .MR_ADDR_WIDTH(MR_ADDR_WIDTH)
    ) u_storage (
        .clk(clk),
        .rst_n(rst_n),
        .load_mr(load_mr),
        .mr_addr(mr_addr),
        .mr_data(mr_data),
        .current_mode(current_mode)
    );

endmodule

module mode_register_storage #(
    parameter MR_ADDR_WIDTH = 4
)(
    input clk,
    input rst_n,
    input load_mr,
    input [MR_ADDR_WIDTH-1:0] mr_addr,
    input [15:0] mr_data,
    output reg [15:0] current_mode
);

    // Pipeline stage 1 signals
    reg [MR_ADDR_WIDTH-1:0] mr_addr_stage1;
    reg [15:0] mr_data_stage1;
    reg load_mr_stage1;
    
    // Pipeline stage 2 signals
    reg [MR_ADDR_WIDTH-1:0] mr_addr_stage2;
    reg [15:0] mr_data_stage2;
    reg load_mr_stage2;
    
    // Mode register array
    reg [15:0] mode_regs [0:(1<<MR_ADDR_WIDTH)-1];
    
    // Stage 1: Address and data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mr_addr_stage1 <= 0;
            mr_data_stage1 <= 0;
            load_mr_stage1 <= 0;
        end else begin
            mr_addr_stage1 <= mr_addr;
            mr_data_stage1 <= mr_data;
            load_mr_stage1 <= load_mr;
        end
    end
    
    // Stage 2: Register write and read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mr_addr_stage2 <= 0;
            mr_data_stage2 <= 0;
            load_mr_stage2 <= 0;
            current_mode <= 0;
        end else begin
            mr_addr_stage2 <= mr_addr_stage1;
            mr_data_stage2 <= mr_data_stage1;
            load_mr_stage2 <= load_mr_stage1;
            
            if (load_mr_stage1)
                mode_regs[mr_addr_stage1] <= mr_data_stage1;
            
            current_mode <= mode_regs[mr_addr_stage2];
        end
    end

endmodule