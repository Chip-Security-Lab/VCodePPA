//SystemVerilog
module reset_polarity_converter (
    input  wire clk,
    input  wire rst_n_in,
    output wire rst_out
);

    wire [1:0] sync_stages_next;
    reg  [1:0] sync_stages_reg;

    // Combinational logic: next state calculation
    assign sync_stages_next = (!rst_n_in) ? 2'b11 : {sync_stages_reg[0], 1'b0};

    // Sequential logic: register update
    always @(posedge clk or negedge rst_n_in) begin
        if (!rst_n_in)
            sync_stages_reg <= 2'b11;
        else
            sync_stages_reg <= sync_stages_next;
    end

    // Output assignment
    assign rst_out = sync_stages_reg[1];

endmodule