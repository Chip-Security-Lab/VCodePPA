//SystemVerilog
module wave19_beep #(
    parameter BEEP_ON  = 50,
    parameter BEEP_OFF = 50,
    parameter WIDTH    = 8
)(
    input  wire clk,
    input  wire rst,
    output reg  beep_out
);
    reg [WIDTH-1:0] cnt;
    reg             state;

    wire [WIDTH-1:0] kogge_stone_sum;
    wire             kogge_stone_carry;

    kogge_stone_adder_8bit u_kogge_stone_adder (
        .a(cnt),
        .b(8'd1),
        .sum(kogge_stone_sum),
        .cout(kogge_stone_carry)
    );

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt      <= 0;
            state    <= 0;
            beep_out <= 0;
        end else begin
            cnt <= kogge_stone_sum;
            if(!state && cnt == BEEP_ON) begin
                state    <= 1;
                cnt      <= 0;
                beep_out <= 0;
            end else if(state && cnt == BEEP_OFF) begin
                state    <= 0;
                cnt      <= 0;
                beep_out <= 1;
            end
        end
    end
endmodule

module kogge_stone_adder_8bit(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] p,g;
    wire [7:0] c;

    // Stage 0: Initial propagate and generate
    assign p = a ^ b;
    assign g = a & b;

    // Stage 1
    wire [7:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    genvar i1;
    generate
        for(i1=1;i1<8;i1=i1+1) begin : gen_stage1
            assign g1[i1] = g[i1] | (p[i1] & g[i1-1]);
            assign p1[i1] = p[i1] & p[i1-1];
        end
    endgenerate

    // Stage 2
    wire [7:0] g2, p2;
    assign g2[0] = g1[0];
    assign g2[1] = g1[1];
    assign p2[0] = p1[0];
    assign p2[1] = p1[1];
    genvar i2;
    generate
        for(i2=2;i2<8;i2=i2+1) begin : gen_stage2
            assign g2[i2] = g1[i2] | (p1[i2] & g1[i2-2]);
            assign p2[i2] = p1[i2] & p1[i2-2];
        end
    endgenerate

    // Stage 3
    wire [7:0] g3;
    assign g3[0] = g2[0];
    assign g3[1] = g2[1];
    assign g3[2] = g2[2];
    assign g3[3] = g2[3];
    genvar i3;
    generate
        for(i3=4;i3<8;i3=i3+1) begin : gen_stage3
            assign g3[i3] = g2[i3] | (p2[i3] & g2[i3-4]);
        end
    endgenerate

    // Carry out
    assign c[0] = 1'b0;
    assign c[1] = g1[0];
    assign c[2] = g2[1];
    assign c[3] = g2[2];
    assign c[4] = g3[3];
    assign c[5] = g3[4];
    assign c[6] = g3[5];
    assign c[7] = g3[6];
    assign cout = g3[7];

    // Sum
    assign sum = p ^ c;

endmodule