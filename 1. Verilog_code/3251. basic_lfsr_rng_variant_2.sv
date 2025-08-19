//SystemVerilog
// Top-level module: Hierarchical LFSR RNG with valid/ready handshake
module basic_lfsr_rng_valid_ready (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rng_ready,
    output wire [15:0] rng_data,
    output wire        rng_valid
);

    // Internal signals for submodule interconnect
    wire [15:0] lfsr_current_data;
    wire [15:0] lfsr_next_data;
    wire        lfsr_update_en;
    wire        valid_reg;
    wire        valid_set;
    wire        valid_clr;

    // LFSR core: generates next LFSR value
    lfsr16_core u_lfsr16_core (
        .lfsr_in   (lfsr_current_data),
        .lfsr_out  (lfsr_next_data)
    );

    // Valid control logic: maintains valid handshake
    rng_valid_ctrl u_rng_valid_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),
        .rng_ready    (rng_ready),
        .valid_in     (valid_reg),
        .valid_set    (valid_set),
        .valid_clr    (valid_clr),
        .valid_out    (rng_valid)
    );

    // LFSR state register: holds LFSR state and manages update
    lfsr16_state_reg u_lfsr16_state_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .lfsr_next    (lfsr_next_data),
        .lfsr_update  (lfsr_update_en),
        .lfsr_out     (lfsr_current_data)
    );

    // Output register: holds output data
    rng_output_reg u_rng_output_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_in      (lfsr_current_data),
        .data_next    (lfsr_next_data),
        .valid_in     (valid_reg),
        .valid_set    (valid_set),
        .valid_clr    (valid_clr),
        .rng_ready    (rng_ready),
        .rng_valid    (rng_valid),
        .rng_data     (rng_data),
        .lfsr_update  (lfsr_update_en),
        .valid_reg    (valid_reg)
    );

endmodule

// LFSR core: Computes next value based on polynomial taps
module lfsr16_core (
    input  wire [15:0] lfsr_in,
    output wire [15:0] lfsr_out
);
    // Feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1
    assign lfsr_out = {lfsr_in[14:0], lfsr_in[15] ^ lfsr_in[13] ^ lfsr_in[12] ^ lfsr_in[10]};
endmodule

// LFSR state register: Holds and updates LFSR state
module lfsr16_state_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] lfsr_next,
    input  wire        lfsr_update,
    output reg  [15:0] lfsr_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_out <= 16'hACE1;
        else if (lfsr_update)
            lfsr_out <= lfsr_next;
    end
endmodule

// Output register: Holds output data and manages output logic
module rng_output_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    input  wire [15:0] data_next,
    input  wire        valid_in,
    input  wire        valid_set,
    input  wire        valid_clr,
    input  wire        rng_ready,
    input  wire        rng_valid,
    output reg  [15:0] rng_data,
    output reg         lfsr_update,
    output reg         valid_reg
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rng_data    <= 16'h0000;
            lfsr_update <= 1'b0;
            valid_reg   <= 1'b0;
        end else begin
            if (valid_in && rng_ready) begin
                rng_data    <= data_next;
                lfsr_update <= 1'b1;
                valid_reg   <= 1'b1;
            end else if (!valid_in) begin
                rng_data    <= data_in;
                lfsr_update <= 1'b0;
                valid_reg   <= 1'b1;
            end else begin
                lfsr_update <= 1'b0;
            end
        end
    end
endmodule

// Valid control logic: Generates valid signal and manages handshake
module rng_valid_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire rng_ready,
    input  wire valid_in,
    input  wire valid_set,
    input  wire valid_clr,
    output reg  valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_out <= 1'b0;
        else if (valid_in && rng_ready)
            valid_out <= 1'b1;
        else if (!valid_in)
            valid_out <= 1'b1;
    end
endmodule