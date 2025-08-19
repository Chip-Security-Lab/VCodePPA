//SystemVerilog
// Top level module
module toggle_ff_count_enable (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       count_en,
    input  wire       ready,
    output wire       valid,
    output wire [3:0] q
);

    // Internal signals for connection between submodules
    wire [3:0] next_q;
    wire       data_valid;

    // Instantiate data generator submodule
    data_generator u_data_generator (
        .count_en   (count_en),
        .q_current  (q),
        .next_q     (next_q),
        .data_valid (data_valid)
    );

    // Instantiate data transfer submodule with handshake
    data_transfer u_data_transfer (
        .clk        (clk),
        .rst_n      (rst_n),
        .next_q     (next_q),
        .data_valid (data_valid),
        .ready      (ready),
        .q          (q),
        .valid      (valid)
    );

endmodule

// Data generation submodule
module data_generator (
    input  wire [3:0] q_current,
    input  wire       count_en,
    output reg  [3:0] next_q,
    output reg        data_valid
);

    // Combinational logic for data generation
    always @(*) begin
        if (count_en)
            next_q = q_current + 1'b1;
        else
            next_q = q_current;
            
        data_valid = count_en;
    end

endmodule

// Data transfer submodule with handshake protocol
module data_transfer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] next_q,
    input  wire       data_valid,
    input  wire       ready,
    output reg  [3:0] q,
    output reg        valid
);

    // Sequential logic for data transfer with handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q     <= 4'b0000;
            valid <= 1'b0;
        end
        else begin
            if (data_valid && ready) begin
                q     <= next_q;
                valid <= 1'b1;
            end
            else if (ready) begin
                valid <= 1'b0;
            end
        end
    end

endmodule