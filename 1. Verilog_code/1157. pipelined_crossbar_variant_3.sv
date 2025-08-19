//SystemVerilog
//IEEE 1364-2005 Verilog
module pipelined_crossbar (
    input wire clock, reset,
    input wire [15:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output wire [15:0] out0, out1, out2, out3
);
    // Stage 1: Input registration
    reg [15:0] in_reg [0:3];
    reg [1:0] sel_reg [0:3];
    
    // Stage 2: Output registration
    reg [15:0] out_reg [0:3];
    
    // Crossbar switching connections (combinational)
    wire [15:0] crossbar_out [0:3];
    
    // Carry Skip adder implementation
    wire [15:0] adder_result;
    wire carry_out;
    
    carry_skip_adder_16bit adder_inst (
        .a(in_reg[sel_reg[0]]),
        .b(in_reg[sel_reg[1]]),
        .cin(1'b0),
        .sum(adder_result),
        .cout(carry_out)
    );
    
    // Combinational logic for crossbar switching with adder enhancement
    generate
        genvar i;
        for (i = 0; i < 4; i = i + 1) begin : crossbar_switching
            if (i == 0) begin
                assign crossbar_out[i] = in_reg[sel_reg[i]];
            end else if (i == 1) begin
                assign crossbar_out[i] = in_reg[sel_reg[i]];
            end else if (i == 2) begin
                // Use the carry skip adder result for output 2
                assign crossbar_out[i] = adder_result;
            end else begin
                // Use a modified version for output 3
                assign crossbar_out[i] = {carry_out, adder_result[15:1]};
            end
        end
    endgenerate
    
    // Sequential logic for input registration
    always @(posedge clock) begin
        if (reset) begin
            in_reg[0] <= 16'h0000;
            in_reg[1] <= 16'h0000;
            in_reg[2] <= 16'h0000;
            in_reg[3] <= 16'h0000;
            sel_reg[0] <= 2'b00;
            sel_reg[1] <= 2'b00;
            sel_reg[2] <= 2'b00;
            sel_reg[3] <= 2'b00;
        end else begin
            in_reg[0] <= in0;
            in_reg[1] <= in1;
            in_reg[2] <= in2;
            in_reg[3] <= in3;
            sel_reg[0] <= sel0;
            sel_reg[1] <= sel1;
            sel_reg[2] <= sel2;
            sel_reg[3] <= sel3;
        end
    end
    
    // Sequential logic for output registration
    always @(posedge clock) begin
        if (reset) begin
            out_reg[0] <= 16'h0000;
            out_reg[1] <= 16'h0000;
            out_reg[2] <= 16'h0000;
            out_reg[3] <= 16'h0000;
        end else begin
            out_reg[0] <= crossbar_out[0];
            out_reg[1] <= crossbar_out[1];
            out_reg[2] <= crossbar_out[2];
            out_reg[3] <= crossbar_out[3];
        end
    end
    
    // Output assignments
    assign out0 = out_reg[0];
    assign out1 = out_reg[1];
    assign out2 = out_reg[2];
    assign out3 = out_reg[3];
endmodule

// 16-bit Carry-Skip Adder implementation
module carry_skip_adder_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire cin,
    output wire [15:0] sum,
    output wire cout
);
    // Define block size for carry-skip (4-bit blocks)
    parameter BLOCK_SIZE = 4;
    parameter NUM_BLOCKS = 16 / BLOCK_SIZE;
    
    // Internal carry signals
    wire [NUM_BLOCKS:0] block_carry;
    
    // Propagate signals for each block
    wire [NUM_BLOCKS-1:0] block_p;
    
    // Assign input carry
    assign block_carry[0] = cin;
    
    // Generate carry-skip blocks
    genvar i, j;
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin : carry_skip_blocks
            wire [BLOCK_SIZE-1:0] p;  // Propagate signals within block
            wire [BLOCK_SIZE:0] c;    // Internal carries within block
            
            // Input carry to the block
            assign c[0] = block_carry[i];
            
            // Full adders within each block
            for (j = 0; j < BLOCK_SIZE; j = j + 1) begin : full_adders
                wire s_temp;
                
                // Full adder sum and carry equations
                assign p[j] = a[i*BLOCK_SIZE+j] ^ b[i*BLOCK_SIZE+j];
                assign s_temp = p[j] ^ c[j];
                assign c[j+1] = (a[i*BLOCK_SIZE+j] & b[i*BLOCK_SIZE+j]) | 
                                (p[j] & c[j]);
                
                // Connect sum output
                assign sum[i*BLOCK_SIZE+j] = s_temp;
            end
            
            // Block propagate (P) signal - true when all bits in block can propagate carry
            assign block_p[i] = &p;
            
            // Skip logic for the block
            assign block_carry[i+1] = block_p[i] ? block_carry[i] : c[BLOCK_SIZE];
        end
    endgenerate
    
    // Final carry output
    assign cout = block_carry[NUM_BLOCKS];
endmodule