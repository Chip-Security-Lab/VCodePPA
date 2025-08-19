//SystemVerilog
// Top level module
module seg7_sync_decoder (
    input clk, rst_n, en,
    input [3:0] bcd,
    output [6:0] seg
);
    // Internal signals
    wire [6:0] decoded_seg;
    wire [3:0] bcd_pipe;
    
    // Pipeline register for input
    bcd_pipeline_register bcd_pipe_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .bcd_in(bcd),
        .bcd_out(bcd_pipe)
    );
    
    // Instantiate decoder module with pipelined input
    bcd_to_seg7_decoder bcd_decoder (
        .bcd(bcd_pipe),
        .seg(decoded_seg)
    );
    
    // Instantiate output register module
    seg7_output_register seg_register (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .seg_in(decoded_seg),
        .seg_out(seg)
    );
endmodule

// Input pipeline register module
module bcd_pipeline_register (
    input clk, rst_n, en,
    input [3:0] bcd_in,
    output reg [3:0] bcd_out
);
    // Pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            bcd_out <= 4'b0000;
        else if (en)
            bcd_out <= bcd_in;
    end
endmodule

// BCD to 7-segment decoder module with optimized logic
module bcd_to_seg7_decoder (
    input [3:0] bcd,
    output reg [6:0] seg
);
    // Combinational logic for decoding
    // Lower 3 bits pre-decode
    reg [3:0] segment_pattern_low;
    
    always @(*) begin
        case(bcd[2:0])
            3'd0: segment_pattern_low = 4'h3;
            3'd1: segment_pattern_low = 4'h6;
            3'd2: segment_pattern_low = 4'hB;
            3'd3: segment_pattern_low = 4'hF;
            3'd4: segment_pattern_low = 4'h6;
            3'd5: segment_pattern_low = 4'hD;
            3'd6: segment_pattern_low = 4'hD;
            3'd7: segment_pattern_low = 4'h7;
            default: segment_pattern_low = 4'h0;
        endcase
        
        // Final decode using MSB and pre-decoded pattern
        case({bcd[3], segment_pattern_low})
            5'b0_0011: seg = 7'h3F; // 0
            5'b0_0110: seg = 7'h06; // 1
            5'b0_1011: seg = 7'h5B; // 2
            5'b0_1111: seg = 7'h4F; // 3
            5'b0_0110: seg = 7'h66; // 4
            5'b0_1101: seg = 7'h6D; // 5
            5'b0_1101: seg = 7'h7D; // 6
            5'b0_0111: seg = 7'h07; // 7
            5'b1_0011: seg = 7'h7F; // 8
            5'b1_0110: seg = 7'h6F; // 9
            default: seg = 7'h00;
        endcase
    end
endmodule

// Output register module with synchronous logic
module seg7_output_register (
    input clk, rst_n, en,
    input [6:0] seg_in,
    output reg [6:0] seg_out
);
    // Registered output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            seg_out <= 7'h00;
        else if (en)
            seg_out <= seg_in;
    end
endmodule