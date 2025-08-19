//SystemVerilog
module SignedMultiplier(
    input clk,
    input rst_n,
    input req,
    input signed [7:0] a, b,
    output reg ack,
    output reg signed [15:0] result
);

    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;
    
    reg state, next_state;
    reg signed [15:0] calc_result;
    wire signed [15:0] wallace_result;
    
    // Wallace Tree Multiplier
    WallaceTreeMultiplier wallace_inst (
        .a(a),
        .b(b),
        .result(wallace_result)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        case (state)
            IDLE: next_state = req ? CALC : IDLE;
            CALC: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            result <= 16'd0;
            calc_result <= 16'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    ack <= 1'b0;
                    if (req) begin
                        calc_result <= wallace_result;
                    end
                end
                CALC: begin
                    ack <= 1'b1;
                    result <= calc_result;
                end
                default: begin
                    ack <= 1'b0;
                end
            endcase
        end
    end
endmodule

module WallaceTreeMultiplier(
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [15:0] result
);
    // Partial Products Generation
    wire [7:0][7:0] pp;
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            for (j = 0; j < 8; j = j + 1) begin : pp_bit
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate

    // First Stage: 8x8 to 4x8
    wire [7:0][7:0] stage1;
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage1_gen
            assign stage1[i] = pp[2*i] ^ pp[2*i+1];
        end
    endgenerate

    // Second Stage: 4x8 to 2x8
    wire [7:0][7:0] stage2;
    generate
        for (i = 0; i < 2; i = i + 1) begin : stage2_gen
            assign stage2[i] = stage1[2*i] ^ stage1[2*i+1];
        end
    endgenerate

    // Final Stage: 2x8 to 1x16
    wire [15:0] final_sum;
    assign final_sum = {8'b0, stage2[0]} + {8'b0, stage2[1]};

    // Sign Extension and Final Result
    assign result = final_sum;
endmodule