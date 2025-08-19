//SystemVerilog
module multi_stage_arith_shifter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] in_value,
    input  wire [3:0]  shift_amount,
    output wire [15:0] out_value
);

    reg  [15:0] stage1_data;
    reg  [15:0] stage2_data;
    reg  [15:0] stage3_data;
    reg  [15:0] out_value_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data    <= 16'd0;
            stage2_data    <= 16'd0;
            stage3_data    <= 16'd0;
            out_value_reg  <= 16'd0;
        end else begin
            // Stage 1: Shift by 8 bits if shift_amount[3]
            if (shift_amount[3])
                stage1_data <= {{8{in_value[15]}}, in_value[15:8]};
            else
                stage1_data <= in_value;

            // Stage 2: Shift by 4 bits if shift_amount[2]
            if (shift_amount[2])
                stage2_data <= {{4{stage1_data[15]}}, stage1_data[15:4]};
            else
                stage2_data <= stage1_data;

            // Stage 3: Shift by 1/2/3 bits based on shift_amount[1:0]
            case (shift_amount[1:0])
                2'b00: stage3_data <= stage2_data;
                2'b01: stage3_data <= {{1{stage2_data[15]}}, stage2_data[15:1]};
                2'b10: stage3_data <= {{2{stage2_data[15]}}, stage2_data[15:2]};
                2'b11: stage3_data <= {{3{stage2_data[15]}}, stage2_data[15:3]};
                default: stage3_data <= stage2_data;
            endcase

            // Output stage with pipeline register for timing closure
            out_value_reg <= stage3_data;
        end
    end

    assign out_value = out_value_reg;

endmodule