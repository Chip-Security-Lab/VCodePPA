//SystemVerilog
module StageEnabledShifter #(parameter WIDTH=8) (
    input clk, 
    input [WIDTH-1:0] stage_en,
    input serial_in,
    output reg [WIDTH-1:0] parallel_out
);

    wire [WIDTH-1:0] adder_a_wire;
    wire [WIDTH-1:0] adder_b_wire;
    wire [WIDTH-1:0] adder_sum_wire;

    reg [WIDTH-1:0] shifter_data_reg;
    reg [WIDTH-1:0] adder_a_pipe_reg;
    reg [WIDTH-1:0] adder_b_pipe_reg;
    reg [WIDTH-1:0] adder_sum_pipe_reg;

    // Pipeline stage 1: shifter logic
    genvar i;
    generate
        for(i=0; i<WIDTH; i=i+1) begin : shifter_stage
            always @(posedge clk) begin
                if (stage_en[i] && (i == 0))
                    shifter_data_reg[i] <= serial_in;
                else if (stage_en[i] && (i != 0))
                    shifter_data_reg[i] <= shifter_data_reg[i-1];
            end
        end
    endgenerate

    // Pipeline stage 2: register adder inputs
    always @(posedge clk) begin
        adder_a_pipe_reg <= shifter_data_reg;
        adder_b_pipe_reg <= stage_en;
    end

    assign adder_a_wire = adder_a_pipe_reg;
    assign adder_b_wire = adder_b_pipe_reg;

    // Pipeline stage 3: instantiate pipelined adder, insert register for sum
    CarryLookaheadAdder8 carry_lookahead_adder_inst (
        .clk(clk),
        .a(adder_a_wire),
        .b(adder_b_wire),
        .cin(1'b0),
        .sum(adder_sum_wire),
        .cout()
    );

    always @(posedge clk) begin
        adder_sum_pipe_reg <= adder_sum_wire; // Pipeline register for adder sum
    end

    // Pipeline stage 4: output register
    always @(posedge clk) begin
        parallel_out <= adder_sum_pipe_reg;
    end

endmodule

// 8-bit Carry Lookahead Adder Module with pipeline register on output
module CarryLookaheadAdder8 (
    input clk,
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    reg [7:0] generate_reg;
    reg [7:0] propagate_reg;
    reg [7:0] carry_reg;
    reg [7:0] sum_reg;
    reg cout_reg;

    wire [7:0] generate_wire;
    wire [7:0] propagate_wire;
    wire [7:0] carry_wire;
    wire [7:0] sum_wire;
    wire cout_wire;

    assign generate_wire = a & b;
    assign propagate_wire = a ^ b;

    assign carry_wire[0] = cin;
    assign carry_wire[1] = generate_wire[0] | (propagate_wire[0] & carry_wire[0]);
    assign carry_wire[2] = generate_wire[1] | (propagate_wire[1] & generate_wire[0]) | (propagate_wire[1] & propagate_wire[0] & carry_wire[0]);
    assign carry_wire[3] = generate_wire[2] | (propagate_wire[2] & generate_wire[1]) | (propagate_wire[2] & propagate_wire[1] & generate_wire[0]) | (propagate_wire[2] & propagate_wire[1] & propagate_wire[0] & carry_wire[0]);
    assign carry_wire[4] = generate_wire[3] | (propagate_wire[3] & generate_wire[2]) | (propagate_wire[3] & propagate_wire[2] & generate_wire[1]) | (propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & generate_wire[0]) | (propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & propagate_wire[0] & carry_wire[0]);
    assign carry_wire[5] = generate_wire[4] | (propagate_wire[4] & generate_wire[3]) | (propagate_wire[4] & propagate_wire[3] & generate_wire[2]) | (propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & generate_wire[1]) | (propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & generate_wire[0]) | (propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & propagate_wire[0] & carry_wire[0]);
    assign carry_wire[6] = generate_wire[5] | (propagate_wire[5] & generate_wire[4]) | (propagate_wire[5] & propagate_wire[4] & generate_wire[3]) | (propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & generate_wire[2]) | (propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & generate_wire[1]) | (propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & generate_wire[0]) | (propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & propagate_wire[0] & carry_wire[0]);
    assign carry_wire[7] = generate_wire[6] | (propagate_wire[6] & generate_wire[5]) | (propagate_wire[6] & propagate_wire[5] & generate_wire[4]) | (propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & generate_wire[3]) | (propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & generate_wire[2]) | (propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & generate_wire[1]) | (propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & generate_wire[0]) | (propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & propagate_wire[0] & carry_wire[0]);
    assign cout_wire = generate_wire[7] | (propagate_wire[7] & generate_wire[6]) | (propagate_wire[7] & propagate_wire[6] & generate_wire[5]) | (propagate_wire[7] & propagate_wire[6] & propagate_wire[5] & generate_wire[4]) | (propagate_wire[7] & propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & generate_wire[3]) | (propagate_wire[7] & propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & generate_wire[2]) | (propagate_wire[7] & propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & generate_wire[1]) | (propagate_wire[7] & propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & generate_wire[0]) | (propagate_wire[7] & propagate_wire[6] & propagate_wire[5] & propagate_wire[4] & propagate_wire[3] & propagate_wire[2] & propagate_wire[1] & propagate_wire[0] & carry_wire[0]);

    assign sum_wire[0] = propagate_wire[0] ^ cin;
    assign sum_wire[1] = propagate_wire[1] ^ carry_wire[1];
    assign sum_wire[2] = propagate_wire[2] ^ carry_wire[2];
    assign sum_wire[3] = propagate_wire[3] ^ carry_wire[3];
    assign sum_wire[4] = propagate_wire[4] ^ carry_wire[4];
    assign sum_wire[5] = propagate_wire[5] ^ carry_wire[5];
    assign sum_wire[6] = propagate_wire[6] ^ carry_wire[6];
    assign sum_wire[7] = propagate_wire[7] ^ carry_wire[7];

    always @(posedge clk) begin
        generate_reg   <= generate_wire;
        propagate_reg  <= propagate_wire;
        carry_reg      <= carry_wire;
        sum_reg        <= sum_wire;
        cout_reg       <= cout_wire;
    end

    assign sum = sum_reg;
    assign cout = cout_reg;

endmodule