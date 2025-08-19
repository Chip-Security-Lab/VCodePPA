//SystemVerilog
// Top-level module
module ProgIntervalTimer (
    input wire clk, 
    input wire rst_n, 
    input wire load,
    input wire [15:0] threshold,
    output wire intr
);
    // Internal signals for connecting submodules
    wire [15:0] cnt_value;
    wire cnt_is_one;
    
    // Counter submodule instantiation
    TimerCounter timer_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .threshold(threshold),
        .cnt_value(cnt_value),
        .cnt_is_one(cnt_is_one)
    );
    
    // Interrupt generator submodule instantiation
    InterruptGenerator intr_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cnt_is_one(cnt_is_one),
        .intr(intr)
    );
    
endmodule

// Counter logic submodule with LUT-assisted subtractor
module TimerCounter (
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire [15:0] threshold,
    output reg [15:0] cnt_value,
    output wire cnt_is_one
);
    // LUT for 4-bit subtraction
    reg [3:0] lut_sub_result;
    reg lut_borrow_out;
    
    // Subtraction using LUT-assisted algorithm
    wire [15:0] next_value;
    wire [4:0] borrow; // Extra bit for initial borrow
    
    // Initial borrow is 0
    assign borrow[0] = 1'b0;
    
    // Generate flag when counter reaches one
    assign cnt_is_one = (cnt_value == 16'd1);
    
    // LUT-based subtraction for each 4-bit segment
    // First 4-bit segment (bits 3:0)
    always @(*) begin
        case ({cnt_value[3:0], borrow[0]})
            5'b00000: begin lut_borrow_out = 1'b0; lut_sub_result = 4'b0000; end
            5'b00001: begin lut_borrow_out = 1'b1; lut_sub_result = 4'b1111; end
            5'b00010: begin lut_borrow_out = 1'b0; lut_sub_result = 4'b0001; end
            5'b00011: begin lut_borrow_out = 1'b0; lut_sub_result = 4'b0000; end
            5'b00100: begin lut_borrow_out = 1'b0; lut_sub_result = 4'b0010; end
            5'b00101: begin lut_borrow_out = 1'b0; lut_sub_result = 4'b0001; end
            
            // ... more LUT entries would be here in a real implementation
            // Only showing a few representative entries for readability
            
            5'b11110: begin lut_borrow_out = 1'b0; lut_sub_result = 4'b1110; end
            5'b11111: begin lut_borrow_out = 1'b0; lut_sub_result = 4'b1101; end
            default: begin
                lut_borrow_out = (cnt_value[3:0] == 4'b0 && borrow[0]) ? 1'b1 : 1'b0;
                lut_sub_result = (cnt_value[3:0] == 4'b0 && borrow[0]) ? 4'b1111 : (cnt_value[3:0] - borrow[0]);
            end
        endcase
    end
    
    assign next_value[3:0] = lut_sub_result;
    assign borrow[1] = lut_borrow_out;
    
    // LUT-based subtraction for second 4-bit segment (bits 7:4)
    wire segment2_borrow;
    wire [3:0] segment2_result;
    wire [3:0] segment2_no_borrow_result;
    wire [3:0] segment2_with_borrow_result;
    
    assign segment2_no_borrow_result = cnt_value[7:4];
    assign segment2_with_borrow_result = cnt_value[7:4] - 1'b1;
    assign segment2_result = (cnt_value[7:4] == 4'b0 && borrow[1]) ? 4'b1111 : 
                             (borrow[1] ? segment2_with_borrow_result : segment2_no_borrow_result);
    assign segment2_borrow = (cnt_value[7:4] == 4'b0 && borrow[1]) ? 1'b1 : 1'b0;
    
    assign next_value[7:4] = segment2_result;
    assign borrow[2] = segment2_borrow;
    
    // LUT-based subtraction for third 4-bit segment (bits 11:8)
    wire segment3_borrow;
    wire [3:0] segment3_result;
    wire [3:0] segment3_no_borrow_result;
    wire [3:0] segment3_with_borrow_result;
    
    assign segment3_no_borrow_result = cnt_value[11:8];
    assign segment3_with_borrow_result = cnt_value[11:8] - 1'b1;
    assign segment3_result = (cnt_value[11:8] == 4'b0 && borrow[2]) ? 4'b1111 : 
                             (borrow[2] ? segment3_with_borrow_result : segment3_no_borrow_result);
    assign segment3_borrow = (cnt_value[11:8] == 4'b0 && borrow[2]) ? 1'b1 : 1'b0;
    
    assign next_value[11:8] = segment3_result;
    assign borrow[3] = segment3_borrow;
    
    // LUT-based subtraction for fourth 4-bit segment (bits 15:12)
    wire segment4_borrow;
    wire [3:0] segment4_result;
    wire [3:0] segment4_no_borrow_result;
    wire [3:0] segment4_with_borrow_result;
    
    assign segment4_no_borrow_result = cnt_value[15:12];
    assign segment4_with_borrow_result = cnt_value[15:12] - 1'b1;
    assign segment4_result = (cnt_value[15:12] == 4'b0 && borrow[3]) ? 4'b1111 : 
                             (borrow[3] ? segment4_with_borrow_result : segment4_no_borrow_result);
    assign segment4_borrow = (cnt_value[15:12] == 4'b0 && borrow[3]) ? 1'b1 : 1'b0;
    
    assign next_value[15:12] = segment4_result;
    assign borrow[4] = segment4_borrow; // Final borrow (unused)
    
    // Counter logic with explicit multiplexing
    wire [15:0] load_mux_out;
    wire [15:0] decrement_mux_out;
    
    // Multiplexer for load operation
    assign load_mux_out = load ? threshold : decrement_mux_out;
    
    // Multiplexer for counter decrement
    assign decrement_mux_out = (cnt_value == 16'd0) ? 16'd0 : next_value;
    
    // Register update
    always @(posedge clk) begin
        if (!rst_n) 
            cnt_value <= 16'b0;
        else
            cnt_value <= load_mux_out;
    end
    
endmodule

// Interrupt generation submodule
module InterruptGenerator (
    input wire clk,
    input wire rst_n,
    input wire cnt_is_one,
    output reg intr
);
    // Interrupt generation logic with explicit multiplexing
    wire intr_next;
    
    // Multiplexer for interrupt signal
    assign intr_next = cnt_is_one ? 1'b1 : 1'b0;
    
    // Register update
    always @(posedge clk) begin
        if (!rst_n)
            intr <= 1'b0;
        else
            intr <= intr_next;
    end
    
endmodule