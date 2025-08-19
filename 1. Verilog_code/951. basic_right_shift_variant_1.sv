//SystemVerilog
module basic_right_shift #(parameter WIDTH = 8) (
    input wire clk,
    input wire reset_n,
    input wire serial_in,
    input wire valid_in,
    output wire serial_out,
    output wire valid_out
);
    // Pipeline registers for data path
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shift_reg_stage2;
    reg [WIDTH-1:0] shift_reg_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Reset logic for shift register
    always @(posedge clk) begin
        if (!reset_n) begin
            shift_reg_stage1 <= {WIDTH{1'b0}};
        end
        else if (valid_in) begin
            shift_reg_stage1 <= {serial_in, shift_reg_stage3[WIDTH-1:1]};
        end
    end
    
    // Stage 1: Reset logic for valid signal
    always @(posedge clk) begin
        if (!reset_n) begin
            valid_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Reset logic for shift register
    always @(posedge clk) begin
        if (!reset_n) begin
            shift_reg_stage2 <= {WIDTH{1'b0}};
        end
        else begin
            shift_reg_stage2 <= shift_reg_stage1;
        end
    end
    
    // Stage 2: Reset logic for valid signal
    always @(posedge clk) begin
        if (!reset_n) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Reset logic for shift register
    always @(posedge clk) begin
        if (!reset_n) begin
            shift_reg_stage3 <= {WIDTH{1'b0}};
        end
        else begin
            shift_reg_stage3 <= shift_reg_stage2;
        end
    end
    
    // Stage 3: Reset logic for valid signal
    always @(posedge clk) begin
        if (!reset_n) begin
            valid_stage3 <= 1'b0;
        end
        else begin
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign serial_out = shift_reg_stage3[0];
    assign valid_out = valid_stage3;
endmodule