//SystemVerilog
module ICMU_AsyncRegGroup #(
    parameter DATA_WIDTH = 64,
    parameter NUM_REGS = 8
)(
    input clk,
    input rst_async,
    input [2:0] int_level,
    input save_req,
    input restore_req,
    inout [DATA_WIDTH-1:0] context_bus
);
    reg [DATA_WIDTH-1:0] reg_group [0:NUM_REGS-1];
    reg [2:0] current_level;
    reg [DATA_WIDTH-1:0] bus_out;
    wire valid_restore;
    wire valid_save;
    wire [2:0] next_level;
    wire [2:0] level_mask;
    
    assign level_mask = {3{!rst_async}};
    assign valid_restore = restore_req & !rst_async;
    assign valid_save = save_req & (int_level < NUM_REGS) & !rst_async;
    assign next_level = int_level & level_mask;
    
    assign context_bus = valid_restore ? bus_out : {DATA_WIDTH{1'bz}};
    
    always @* begin
        bus_out = valid_restore ? reg_group[current_level] : {DATA_WIDTH{1'bz}};
    end

    always @(posedge save_req or posedge rst_async) begin
        if (rst_async) begin
            current_level <= 3'b0;
        end else if (valid_save) begin
            reg_group[int_level] <= context_bus;
            current_level <= int_level;
        end
    end
endmodule