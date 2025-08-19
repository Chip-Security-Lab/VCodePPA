//SystemVerilog
module var_width_shifter(
    input wire clk,
    input wire rst,
    input wire [31:0] data,
    input wire [1:0] width_sel,   // 00:8-bit, 01:16-bit, 10:24-bit, 11:32-bit
    input wire [4:0] shift_amt,
    input wire shift_left,
    output reg [31:0] result
);

    reg [31:0] masked_data_reg;
    reg [31:0] shift_result_reg;
    reg [31:0] shift_accumulator;
    reg [4:0] shift_counter;
    reg shift_active;
    reg [31:0] shift_data_reg;
    reg shift_direction_reg;
    reg [4:0] shift_amt_reg;
    reg [1:0] width_sel_reg;
    reg shift_start;

    // Mask input data according to width_sel
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            masked_data_reg <= 32'b0;
        end else begin
            case (width_sel)
                2'b00: masked_data_reg <= {24'b0, data[7:0]};
                2'b01: masked_data_reg <= {16'b0, data[15:0]};
                2'b10: masked_data_reg <= {8'b0, data[23:0]};
                default: masked_data_reg <= data;
            endcase
        end
    end

    // Register shift parameters on operation start
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_start <= 1'b1;
            shift_data_reg <= 32'b0;
            shift_amt_reg <= 5'b0;
            shift_direction_reg <= 1'b0;
            width_sel_reg <= 2'b0;
        end else begin
            shift_start <= 1'b0;
            if (!shift_active) begin
                shift_data_reg <= masked_data_reg;
                shift_amt_reg <= shift_amt;
                shift_direction_reg <= shift_left;
                width_sel_reg <= width_sel;
                shift_start <= 1'b1;
            end
        end
    end

    // Shift-accumulate FSM for shift operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_accumulator <= 32'b0;
            shift_counter <= 5'd0;
            shift_active <= 1'b0;
            shift_result_reg <= 32'b0;
        end else begin
            if (shift_start) begin
                shift_active <= 1'b1;
                shift_counter <= 5'd0;
                shift_accumulator <= shift_data_reg;
                shift_result_reg <= shift_data_reg;
            end else if (shift_active) begin
                if (shift_counter < shift_amt_reg) begin
                    if (shift_direction_reg) begin
                        // Shift left by one and accumulate
                        shift_accumulator <= shift_accumulator << 1;
                    end else begin
                        // Shift right by one and accumulate
                        shift_accumulator <= shift_accumulator >> 1;
                    end
                    shift_counter <= shift_counter + 1'b1;
                end else begin
                    shift_result_reg <= shift_accumulator;
                    shift_active <= 1'b0;
                end
            end
        end
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 32'b0;
        end else if (!shift_active) begin
            result <= shift_result_reg;
        end
    end

endmodule