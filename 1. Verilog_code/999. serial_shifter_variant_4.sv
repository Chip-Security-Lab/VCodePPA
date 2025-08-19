//SystemVerilog
module serial_shifter(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [1:0] mode,   // 00:hold, 01:left, 10:right, 11:load
    input wire [7:0] data_in,
    input wire serial_in,
    output reg [7:0] data_out
);
    wire mode_hold   = (mode == 2'b00);
    wire mode_left   = (mode == 2'b01);
    wire mode_right  = (mode == 2'b10);
    wire mode_load   = (mode == 2'b11);

    reg [7:0] next_data_out;

    always @(*) begin
        case (1'b1)
            mode_hold:  next_data_out = data_out;
            mode_left:  next_data_out = {data_out[6:0], serial_in};
            mode_right: next_data_out = {serial_in, data_out[7:1]};
            mode_load:  next_data_out = data_in;
            default:    next_data_out = data_out;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'h00;
        else if (enable)
            data_out <= next_data_out;
    end
endmodule

module dadda_multiplier_8bit (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    output reg [15:0] product,
    output reg ready
);
    // Internal signals for partial products
    reg [7:0] pp[7:0];
    reg [15:0] sum_stage1 [3:0];
    reg [15:0] sum_stage2 [1:0];
    reg [15:0] final_sum;
    reg processing;
    integer i;

    // Dadda tree reduction logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'd0;
            ready <= 1'b0;
            processing <= 1'b0;
            final_sum <= 16'd0;
        end else begin
            if (start && !processing) begin
                // Generate partial products
                for (i = 0; i < 8; i = i + 1) begin
                    pp[i] <= operand_b & {8{operand_a[i]}};
                end
                processing <= 1'b1;
                ready <= 1'b0;
            end else if (processing) begin
                // Stage 1: Align and add partial products
                sum_stage1[0] <= {8'd0, pp[0]} + ({7'd0, pp[1], 1'b0});
                sum_stage1[1] <= ({6'd0, pp[2], 2'b0}) + ({5'd0, pp[3], 3'b0});
                sum_stage1[2] <= ({4'd0, pp[4], 4'b0}) + ({3'd0, pp[5], 5'b0});
                sum_stage1[3] <= ({2'd0, pp[6], 6'b0}) + ({1'd0, pp[7], 7'b0});
                // Stage 2: Add results of stage 1
                sum_stage2[0] <= sum_stage1[0] + sum_stage1[1];
                sum_stage2[1] <= sum_stage1[2] + sum_stage1[3];
                // Stage 3: Final addition
                final_sum <= sum_stage2[0] + sum_stage2[1];
                // Output product
                product <= final_sum;
                ready <= 1'b1;
                processing <= 1'b0;
            end else begin
                ready <= 1'b0;
            end
        end
    end
endmodule