//SystemVerilog
// IEEE 1364-2005
module arith_shifter #(parameter WIDTH = 8) (
    input wire clk, rst, shift_en,
    input wire [WIDTH-1:0] data_in,
    input wire [2:0] shift_amt,
    output reg [WIDTH-1:0] result
);
    // Combinational signals for shift operations
    wire [WIDTH-1:0] data_shift4, data_shift2, data_shift1;
    wire [WIDTH-1:0] data_after_shift4, data_after_shift2, data_after_shift1;
    
    // Apply shift operations combinationally
    assign data_shift4 = $signed(data_in) >>> 4;
    assign data_after_shift4 = (shift_en && shift_amt[2]) ? data_shift4 : data_in;
    
    assign data_shift2 = $signed(data_after_shift4) >>> 2;
    assign data_after_shift2 = (shift_en && shift_amt[1]) ? data_shift2 : data_after_shift4;
    
    assign data_shift1 = $signed(data_after_shift2) >>> 1;
    assign data_after_shift1 = (shift_en && shift_amt[0]) ? data_shift1 : data_after_shift2;
    
    // Pipeline stage registers - moved after combinational logic
    reg [WIDTH-1:0] data_stage1;
    reg shift_en_stage1;
    reg [2:0] shift_amt_stage1;
    
    reg [WIDTH-1:0] data_stage2;
    reg shift_en_stage2;
    reg [1:0] shift_amt_stage2;
    
    reg [WIDTH-1:0] data_stage3;
    reg shift_en_stage3;
    reg [0:0] shift_amt_stage3;

    // Pipeline stage 1: Register after first shift operation
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= 0;
            shift_en_stage1 <= 0;
            shift_amt_stage1 <= 0;
        end else begin
            data_stage1 <= data_after_shift4;
            shift_en_stage1 <= shift_en;
            shift_amt_stage1 <= shift_amt;
        end
    end

    // Pipeline stage 2: Register after second shift operation
    always @(posedge clk) begin
        if (rst) begin
            data_stage2 <= 0;
            shift_en_stage2 <= 0;
            shift_amt_stage2 <= 0;
        end else begin
            data_stage2 <= data_after_shift2;
            shift_en_stage2 <= shift_en_stage1;
            shift_amt_stage2 <= shift_amt_stage1[1:0];
        end
    end

    // Pipeline stage 3: Register after third shift operation
    always @(posedge clk) begin
        if (rst) begin
            data_stage3 <= 0;
            shift_en_stage3 <= 0;
            shift_amt_stage3 <= 0;
        end else begin
            data_stage3 <= data_after_shift1;
            shift_en_stage3 <= shift_en_stage2;
            shift_amt_stage3 <= shift_amt_stage2[0:0];
        end
    end

    // Final pipeline stage: Output result
    always @(posedge clk) begin
        if (rst) begin
            result <= 0;
        end else begin
            result <= data_stage3;
        end
    end
endmodule