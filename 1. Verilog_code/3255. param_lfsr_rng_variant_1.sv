//SystemVerilog
module param_lfsr_rng #(
    parameter WIDTH = 16,
    parameter [WIDTH-1:0] SEED = {WIDTH{1'b1}},
    parameter [WIDTH-1:0] TAPS = 16'h8016
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    output wire [WIDTH-1:0] random_value
);
    // High-fanout signals: lfsr_q, lfsr_c, i (loop variable for generate)
    // Buffer for lfsr_q
    reg [WIDTH-1:0] lfsr_q_reg;
    reg [WIDTH-1:0] lfsr_q_buf;
    // Buffer for lfsr_c
    reg [WIDTH-1:0] lfsr_c_buf;
    wire [WIDTH-1:0] lfsr_c_wire;
    // Buffer for i (index) - generate block index, so not a signal in logic, but buffer generated signals
    // Feedback buffer
    wire feedback_wire;
    reg feedback_buf;

    // Combinational feedback calculation
    assign feedback_wire = ^(lfsr_q_buf & TAPS);

    // Buffer feedback to balance loads
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            feedback_buf <= 1'b0;
        else
            feedback_buf <= feedback_wire;
    end

    // Generate next state combinationally
    genvar idx;
    generate
        for (idx = 0; idx < WIDTH; idx = idx + 1) begin : gen_lfsr
            if (idx == WIDTH-1)
                assign lfsr_c_wire[idx] = feedback_buf;
            else
                assign lfsr_c_wire[idx] = lfsr_q_buf[idx+1];
        end
    endgenerate

    // Buffer lfsr_c_wire to lfsr_c_buf
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            lfsr_c_buf <= {WIDTH{1'b0}};
        else
            lfsr_c_buf <= lfsr_c_wire;
    end

    // LFSR register with input buffer
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            lfsr_q_reg <= SEED;
            lfsr_q_buf <= SEED;
        end else if (enable) begin
            lfsr_q_reg <= lfsr_c_buf;
            lfsr_q_buf <= lfsr_c_buf;
        end
    end

    // Output assignment
    assign random_value = lfsr_q_reg;
endmodule