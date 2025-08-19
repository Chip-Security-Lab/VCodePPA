//SystemVerilog
module compare_match_timer (
    input wire i_clock,
    input wire i_nreset,
    input wire i_enable,
    input wire [23:0] i_compare,
    output reg o_match,
    output wire [23:0] o_counter
);

    // Stage 1: Counter logic
    reg [23:0] timer_cnt_stage1;
    reg enable_stage1;
    
    // Carry-Skip Adder signals
    wire [23:0] sum;
    wire [5:0] block_propagate;
    wire [6:0] carry;
    
    // Stage 2: Comparison preparation
    reg [23:0] timer_cnt_stage2;
    reg [23:0] compare_stage2;
    reg enable_stage2;
    
    // Stage 3: Match detection
    reg match_stage3;
    
    // Carry-Skip Adder implementation
    // Each block is 4-bit wide
    assign carry[0] = 1'b0; // Initial carry-in is 0
    
    // Generate block propagate signals for each 4-bit block
    assign block_propagate[0] = &(timer_cnt_stage1[3:0] | 4'hF);
    assign block_propagate[1] = &(timer_cnt_stage1[7:4] | 4'hF);
    assign block_propagate[2] = &(timer_cnt_stage1[11:8] | 4'hF);
    assign block_propagate[3] = &(timer_cnt_stage1[15:12] | 4'hF);
    assign block_propagate[4] = &(timer_cnt_stage1[19:16] | 4'hF);
    assign block_propagate[5] = &(timer_cnt_stage1[23:20] | 4'hF);
    
    // Calculate carry for each block
    carry_block carry_block0(
        .a(timer_cnt_stage1[3:0]),
        .b(4'h1),
        .cin(carry[0]),
        .sum(sum[3:0]),
        .cout(carry[1])
    );
    
    assign carry[2] = block_propagate[1] ? carry[1] : 
                      carry_block1_out;
    wire carry_block1_out;
    carry_block carry_block1(
        .a(timer_cnt_stage1[7:4]),
        .b(4'h0),
        .cin(carry[1]),
        .sum(sum[7:4]),
        .cout(carry_block1_out)
    );
    
    assign carry[3] = block_propagate[2] ? carry[2] : 
                      carry_block2_out;
    wire carry_block2_out;
    carry_block carry_block2(
        .a(timer_cnt_stage1[11:8]),
        .b(4'h0),
        .cin(carry[2]),
        .sum(sum[11:8]),
        .cout(carry_block2_out)
    );
    
    assign carry[4] = block_propagate[3] ? carry[3] : 
                      carry_block3_out;
    wire carry_block3_out;
    carry_block carry_block3(
        .a(timer_cnt_stage1[15:12]),
        .b(4'h0),
        .cin(carry[3]),
        .sum(sum[15:12]),
        .cout(carry_block3_out)
    );
    
    assign carry[5] = block_propagate[4] ? carry[4] : 
                      carry_block4_out;
    wire carry_block4_out;
    carry_block carry_block4(
        .a(timer_cnt_stage1[19:16]),
        .b(4'h0),
        .cin(carry[4]),
        .sum(sum[19:16]),
        .cout(carry_block4_out)
    );
    
    assign carry[6] = block_propagate[5] ? carry[5] : 
                      carry_block5_out;
    wire carry_block5_out;
    carry_block carry_block5(
        .a(timer_cnt_stage1[23:20]),
        .b(4'h0),
        .cin(carry[5]),
        .sum(sum[23:20]),
        .cout(carry_block5_out)
    );
    
    // Pipeline stage 1: Counter increment using carry-skip adder
    always @(posedge i_clock) begin
        if (!i_nreset) begin
            timer_cnt_stage1 <= 24'h000000;
            enable_stage1 <= 1'b0;
        end
        else begin
            enable_stage1 <= i_enable;
            if (i_enable)
                timer_cnt_stage1 <= sum;
        end
    end
    
    // Pipeline stage 2: Register values for comparison
    always @(posedge i_clock) begin
        if (!i_nreset) begin
            timer_cnt_stage2 <= 24'h000000;
            compare_stage2 <= 24'h000000;
            enable_stage2 <= 1'b0;
        end
        else begin
            timer_cnt_stage2 <= timer_cnt_stage1;
            compare_stage2 <= i_compare;
            enable_stage2 <= enable_stage1;
        end
    end
    
    // Pipeline stage 3: Perform comparison and generate match signal
    always @(posedge i_clock) begin
        if (!i_nreset) begin
            match_stage3 <= 1'b0;
        end
        else begin
            match_stage3 <= (timer_cnt_stage2 == compare_stage2) && enable_stage2;
        end
    end
    
    // Output stage: Register match output
    always @(posedge i_clock) begin
        if (!i_nreset) begin
            o_match <= 1'b0;
        end
        else begin
            o_match <= match_stage3;
        end
    end
    
    // Assign counter output to the current count value
    assign o_counter = timer_cnt_stage1;

endmodule

// 4-bit Carry Block for the Carry-Skip Adder
module carry_block(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [4:0] carry;
    assign carry[0] = cin;
    
    // Full adder for each bit
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: adder
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate
    
    assign cout = carry[4];
endmodule