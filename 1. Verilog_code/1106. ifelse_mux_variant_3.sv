//SystemVerilog
module ifelse_mux_valid_ready (
    input wire clk,
    input wire rst_n,
    input wire valid_in,                  // Valid signal for input
    output wire ready_in,                 // Ready signal for input
    input wire control_in,                // Control signal
    input wire [3:0] path_a_in,           // Data path a
    input wire [3:0] path_b_in,           // Data path b
    output reg valid_out,                 // Valid signal for output
    input wire ready_out,                 // Ready signal for output
    output reg [7:0] mul_result_out,      // Multiplier output
    output reg [3:0] selected_out         // Output data path
);

    // Internal registers for handshake and pipeline
    reg [3:0] path_a_reg, path_b_reg;
    reg control_reg;
    reg valid_reg;

    reg [7:0] mul_result_reg;
    reg [3:0] selected_reg;

    // Handshake logic
    assign ready_in = ~valid_reg | (valid_out & ready_out);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg       <= 1'b0;
            path_a_reg      <= 4'd0;
            path_b_reg      <= 4'd0;
            control_reg     <= 1'b0;
        end else if (ready_in && valid_in) begin
            path_a_reg      <= path_a_in;
            path_b_reg      <= path_b_in;
            control_reg     <= control_in;
            valid_reg       <= 1'b1;
        end else if (valid_out && ready_out) begin
            valid_reg       <= 1'b0;
        end
    end

    // Core logic and output pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_result_reg  <= 8'd0;
            selected_reg    <= 4'd0;
            valid_out       <= 1'b0;
        end else if (valid_reg && ready_out) begin
            // Mux selection logic
            if (control_reg == 1'b0)
                selected_reg <= path_a_reg;
            else
                selected_reg <= path_b_reg;

            // Shift-Add Multiplier
            begin : mult_block
                reg [3:0] multiplier;
                reg [3:0] multiplicand;
                reg [7:0] shift_add_result;
                integer i;
                multiplicand = path_a_reg;
                multiplier = path_b_reg;
                shift_add_result = 8'd0;
                for (i = 0; i < 4; i = i + 1) begin
                    if (multiplier[i])
                        shift_add_result = shift_add_result + (multiplicand << i);
                end
                mul_result_reg <= shift_add_result;
            end

            valid_out <= 1'b1;
        end else if (valid_out && ready_out) begin
            valid_out <= 1'b0;
        end
    end

    // Output assignment (registered)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_result_out  <= 8'd0;
            selected_out    <= 4'd0;
        end else if (valid_out && ready_out) begin
            mul_result_out  <= mul_result_reg;
            selected_out    <= selected_reg;
        end
    end

endmodule