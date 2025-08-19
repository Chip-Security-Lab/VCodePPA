//SystemVerilog
module multiplier_hardware (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire valid_in,
    output reg ready_out,
    output reg [15:0] product,
    output reg valid_out,
    input wire ready_in
);

    reg [15:0] product_reg;
    reg calc_done;
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [15:0] partial_sum;
    reg [2:0] shift_count;
    reg calc_active;

    // Control state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calc_active <= 1'b0;
            calc_done <= 1'b0;
            valid_out <= 1'b0;
            shift_count <= 3'b0;
        end else begin
            if (valid_in && ready_out && !calc_active) begin
                calc_active <= 1'b1;
                calc_done <= 1'b0;
                valid_out <= 1'b0;
                shift_count <= 3'b0;
            end else if (calc_active) begin
                if (shift_count == 3'd7) begin
                    calc_active <= 1'b0;
                    calc_done <= 1'b1;
                    valid_out <= 1'b1;
                end else begin
                    shift_count <= shift_count + 1;
                end
            end else if (calc_done && ready_in) begin
                calc_done <= 1'b0;
                valid_out <= 1'b0;
            end
        end
    end

    // Input register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else if (valid_in && ready_out && !calc_active) begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Partial product calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_sum <= 16'b0;
            product_reg <= 16'b0;
        end else if (calc_active) begin
            if (shift_count == 3'b0) begin
                partial_sum <= a_reg[0] ? b_reg : 16'b0;
            end else begin
                partial_sum <= a_reg[shift_count] ? (b_reg << shift_count) : 16'b0;
            end
            product_reg <= product_reg + partial_sum;
        end else if (valid_in && ready_out && !calc_active) begin
            product_reg <= 16'b0;
        end
    end

    // Ready signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ready_out <= 1'b0;
        else
            ready_out <= !calc_active || (calc_done && ready_in);
    end

    // Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            product <= 16'b0;
        else if (valid_out && ready_in)
            product <= product_reg;
    end

endmodule