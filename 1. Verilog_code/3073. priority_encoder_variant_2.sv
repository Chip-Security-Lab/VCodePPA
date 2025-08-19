//SystemVerilog
module priority_encoder(
    input wire clk, rst,
    input wire [7:0] requests,
    input wire enable,
    output reg [2:0] grant_idx,
    output reg valid, error
);
    localparam IDLE=0, CHECK=1, ENCODE=2, ERROR_STATE=3;
    reg [1:0] state, next;
    reg [7:0] req_reg;
    
    // Dadda multiplier implementation
    wire [7:0] dadda_result;
    reg [7:0] dadda_a, dadda_b;
    
    // Dadda multiplier instance
    dadda_multiplier_8bit dadda_inst(
        .a(dadda_a),
        .b(dadda_b),
        .result(dadda_result)
    );
    
    always @(posedge clk or negedge rst)
        if (!rst) begin
            state <= IDLE;
            req_reg <= 8'h00;
            grant_idx <= 3'd0;
            valid <= 1'b0;
            error <= 1'b0;
            dadda_a <= 8'h00;
            dadda_b <= 8'h00;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    error <= 1'b0;
                    if (enable) begin
                        req_reg <= requests;
                        // Prepare inputs for Dadda multiplier
                        dadda_a <= requests;
                        dadda_b <= 8'h01; // Multiply by 1 to get the same value
                    end
                end
                CHECK: begin
                    if (req_reg == 8'h00) error <= 1'b1;
                end
                ENCODE: begin
                    valid <= 1'b1;
                    // Use Dadda multiplier result for encoding
                    if (dadda_result[7]) grant_idx <= 3'd7;
                    else if (dadda_result[6]) grant_idx <= 3'd6;
                    else if (dadda_result[5]) grant_idx <= 3'd5;
                    else if (dadda_result[4]) grant_idx <= 3'd4;
                    else if (dadda_result[3]) grant_idx <= 3'd3;
                    else if (dadda_result[2]) grant_idx <= 3'd2;
                    else if (dadda_result[1]) grant_idx <= 3'd1;
                    else grant_idx <= 3'd0;
                end
                ERROR_STATE: begin
                    error <= 1'b1;
                    valid <= 1'b0;
                end
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: begin
                if (enable) begin
                    next = CHECK;
                end else begin
                    next = IDLE;
                end
            end
            CHECK: begin
                if (req_reg == 8'h00) begin
                    next = ERROR_STATE;
                end else begin
                    next = ENCODE;
                end
            end
            ENCODE: begin
                next = IDLE;
            end
            ERROR_STATE: begin
                next = IDLE;
            end
            default: begin
                next = IDLE;
            end
        endcase
endmodule

// 8-bit Dadda multiplier implementation
module dadda_multiplier_8bit(
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] result
);
    // Partial products generation
    wire [7:0] pp [7:0];
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_bit
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda tree reduction
    // Level 1: 8:4 compressor
    wire [7:0] level1_sum, level1_carry;
    wire [7:0] level1_out;
    
    // First level compression
    assign level1_sum[0] = pp[0][0];
    assign level1_carry[0] = 1'b0;
    
    genvar k;
    generate
        for (k = 1; k < 8; k = k + 1) begin : gen_level1
            // 3:2 compressor for each column
            wire [2:0] inputs;
            assign inputs = {pp[k][0], pp[k-1][1], pp[k-2][2]};
            
            // Full adder implementation
            wire sum, cout;
            full_adder fa_inst(
                .a(inputs[0]),
                .b(inputs[1]),
                .cin(inputs[2]),
                .sum(sum),
                .cout(cout)
            );
            
            assign level1_sum[k] = sum;
            assign level1_carry[k] = cout;
        end
    endgenerate
    
    // Level 2: 4:2 compressor
    wire [7:0] level2_sum, level2_carry;
    
    // Second level compression
    assign level2_sum[0] = level1_sum[0];
    assign level2_carry[0] = level1_carry[0];
    
    generate
        for (k = 1; k < 8; k = k + 1) begin : gen_level2
            // 4:2 compressor for each column
            wire [3:0] inputs;
            assign inputs = {level1_sum[k], level1_carry[k-1], pp[k][k], pp[k-1][k+1]};
            
            // 4:2 compressor implementation
            wire sum, cout;
            compressor_4to2 comp_inst(
                .in(inputs),
                .sum(sum),
                .cout(cout)
            );
            
            assign level2_sum[k] = sum;
            assign level2_carry[k] = cout;
        end
    endgenerate
    
    // Final addition
    wire [8:0] final_sum;
    assign final_sum = level2_sum + {level2_carry[7:0], 1'b0};
    
    // Output assignment
    assign result = final_sum[7:0];
endmodule

// Full adder module
module full_adder(
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

// 4:2 compressor module
module compressor_4to2(
    input wire [3:0] in,
    output wire sum, cout
);
    wire [1:0] temp_sum;
    wire temp_cout;
    
    // First stage: 3:2 compression
    full_adder fa1(
        .a(in[0]),
        .b(in[1]),
        .cin(in[2]),
        .sum(temp_sum[0]),
        .cout(temp_cout)
    );
    
    // Second stage: 2:2 compression
    full_adder fa2(
        .a(temp_sum[0]),
        .b(in[3]),
        .cin(temp_cout),
        .sum(sum),
        .cout(cout)
    );
endmodule