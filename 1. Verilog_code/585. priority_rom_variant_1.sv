//SystemVerilog
module priority_rom (
    input clk,
    input rst_n,
    input [3:0] addr_high,
    input [3:0] addr_low,
    input high_priority,
    output reg [7:0] data
);

    // ROM memory
    reg [7:0] rom [0:15];
    
    // Pipeline registers
    reg [3:0] addr_high_stage1;
    reg [3:0] addr_low_stage1;
    reg high_priority_stage1;
    
    reg [7:0] data_high_stage2;
    reg [7:0] data_low_stage2;
    reg high_priority_stage2;
    
    // Valid signals for pipeline stages
    reg valid_stage1;
    reg valid_stage2;

    // Optimized comparison logic
    wire [7:0] data_high;
    wire [7:0] data_low;
    wire [7:0] selected_data;

    initial begin
        rom[0] = 8'h55; rom[1] = 8'h66;
    end

    // Stage 1: Address and priority capture with optimized timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_high_stage1 <= 4'b0;
            addr_low_stage1 <= 4'b0;
            high_priority_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_high_stage1 <= addr_high;
            addr_low_stage1 <= addr_low;
            high_priority_stage1 <= high_priority;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: ROM access with parallel read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_high_stage2 <= 8'b0;
            data_low_stage2 <= 8'b0;
            high_priority_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            data_high_stage2 <= rom[addr_high_stage1];
            data_low_stage2 <= rom[addr_low_stage1];
            high_priority_stage2 <= high_priority_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Optimized priority selection using multiplexer
    assign data_high = data_high_stage2;
    assign data_low = data_low_stage2;
    assign selected_data = high_priority_stage2 ? data_high : data_low;

    // Stage 3: Output with optimized timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'b0;
        end else if (valid_stage2) begin
            data <= selected_data;
        end
    end

endmodule