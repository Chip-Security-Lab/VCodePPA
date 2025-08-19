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
    reg [2:0] current_level_stage1;
    reg [2:0] current_level_stage2;
    reg [DATA_WIDTH-1:0] bus_out_stage1;
    reg [DATA_WIDTH-1:0] bus_out_stage2;
    reg save_req_sync;
    reg restore_req_sync;
    reg [2:0] int_level_sync;
    reg [DATA_WIDTH-1:0] context_bus_sync;
    
    // Stage 1: Input synchronization
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            save_req_sync <= 0;
            restore_req_sync <= 0;
            int_level_sync <= 0;
            context_bus_sync <= 0;
        end else begin
            save_req_sync <= save_req;
            restore_req_sync <= restore_req;
            int_level_sync <= int_level;
            context_bus_sync <= context_bus;
        end
    end

    // Stage 2: Register update and level tracking
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            current_level_stage1 <= 0;
        end else begin
            if (save_req_sync) begin
                // Using two's complement addition for subtraction
                reg [2:0] level_diff;
                reg [2:0] level_comp;
                reg [2:0] level_sum;
                
                level_comp = ~int_level_sync + 1'b1;  // Two's complement
                level_sum = NUM_REGS + level_comp;    // Addition
                level_diff = level_sum[2:0];          // Take lower 3 bits
                
                if (level_diff[2] == 0) begin         // Check if result is positive
                    reg_group[int_level_sync] <= context_bus_sync;
                    current_level_stage1 <= int_level_sync;
                end
            end
        end
    end

    // Stage 3: Output preparation
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            current_level_stage2 <= 0;
            bus_out_stage1 <= {DATA_WIDTH{1'bz}};
        end else begin
            current_level_stage2 <= current_level_stage1;
            if (restore_req_sync) begin
                bus_out_stage1 <= reg_group[current_level_stage1];
            end else begin
                bus_out_stage1 <= {DATA_WIDTH{1'bz}};
            end
        end
    end

    // Stage 4: Output synchronization
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            bus_out_stage2 <= {DATA_WIDTH{1'bz}};
        end else begin
            bus_out_stage2 <= bus_out_stage1;
        end
    end

    assign context_bus = restore_req_sync && !rst_async ? bus_out_stage2 : {DATA_WIDTH{1'bz}};
endmodule