//SystemVerilog
module async_right_logical_shifter #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);

    // Instantiate shift control module
    shift_control #(
        .WIDTH(WIDTH)
    ) shift_ctrl (
        .in_data(in_data),
        .shift_amt(shift_amt),
        .out_data(out_data)
    );

    // Verification code
    // synthesis translate_off
    initial begin
        $display("Async Right Logical Shifter, Width=%0d", WIDTH);
    end
    // synthesis translate_on
endmodule

module shift_control #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] in_data,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] out_data
);
    // Implement barrel shifter with carry lookahead structure for 8-bit
    logic [WIDTH-1:0] shift_stage1, shift_stage2, shift_stage3, shift_stage4;
    
    // Generate propagate signals
    logic [WIDTH-1:0] p;
    assign p = ~in_data;
    
    // Combined always block for all shift stages
    always_comb begin
        // Stage 1: Shift by 1 if shift_amt[0]
        if (shift_amt[0]) begin
            shift_stage1 = {1'b0, in_data[WIDTH-1:1]};
        end else begin
            shift_stage1 = in_data;
        end
        
        // Stage 2: Shift by 2 if shift_amt[1]
        if (shift_amt[1]) begin
            shift_stage2 = {2'b0, shift_stage1[WIDTH-1:2]};
        end else begin
            shift_stage2 = shift_stage1;
        end
        
        // Stage 3: Shift by 4 if shift_amt[2]
        if (shift_amt[2]) begin
            shift_stage3 = {4'b0, shift_stage2[WIDTH-1:4]};
        end else begin
            shift_stage3 = shift_stage2;
        end
        
        // Stage 4: Shift by 8 if shift_amt[3] (for WIDTH > 8)
        if (WIDTH > 8) begin
            if (shift_amt[3]) begin
                shift_stage4 = {8'b0, shift_stage3[WIDTH-1:8]};
            end else begin
                shift_stage4 = shift_stage3;
            end
        end
    end
    
    // Output assignment
    assign out_data = (WIDTH > 8) ? shift_stage4 : shift_stage3;
endmodule