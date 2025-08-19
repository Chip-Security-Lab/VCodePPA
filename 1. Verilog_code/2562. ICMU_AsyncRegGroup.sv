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
    
    assign context_bus = restore_req && !rst_async ? bus_out : {DATA_WIDTH{1'bz}};
    
    always @* begin
        if (restore_req && !rst_async)
            bus_out = reg_group[current_level];
        else
            bus_out = {DATA_WIDTH{1'bz}};
    end

    always @(posedge save_req or posedge rst_async) begin
        if (rst_async) begin
            current_level <= 0;
        end else begin
            if (save_req && (int_level < NUM_REGS)) begin
                reg_group[int_level] <= context_bus;
                current_level <= int_level;
            end
        end
    end
endmodule