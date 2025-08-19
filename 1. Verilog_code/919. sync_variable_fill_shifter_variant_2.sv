//SystemVerilog
module sync_variable_fill_shifter (
    input                clk,
    input                rst,
    input      [7:0]     data_in,
    input      [2:0]     shift_val,
    input                shift_dir,  // 0: left, 1: right
    input                fill_bit,   // Value to fill vacant positions
    output reg [7:0]     data_out
);
    // Temporary variables for barrel shifter implementation
    wire [7:0] stage0_right, stage0_left;
    wire [7:0] stage1_right, stage1_left;
    wire [7:0] stage2_right, stage2_left;
    wire [7:0] fill_value;
    wire [7:0] final_shift;
    
    // Fill value based on fill_bit
    assign fill_value = fill_bit ? 8'hFF : 8'h00;
    
    // Barrel shifter implementation
    // Stage 0: Shift by 0 or 1 bit
    assign stage0_right = shift_val[0] ? {fill_value[0], data_in[7:1]} : data_in;
    assign stage0_left = shift_val[0] ? {data_in[6:0], fill_bit} : data_in;
    
    // Stage 1: Shift by 0 or 2 bits
    assign stage1_right = shift_val[1] ? {fill_value[1:0], stage0_right[7:2]} : stage0_right;
    assign stage1_left = shift_val[1] ? {stage0_left[5:0], {2{fill_bit}}} : stage0_left;
    
    // Stage 2: Shift by 0 or 4 bits
    assign stage2_right = shift_val[2] ? {fill_value[3:0], stage1_right[7:4]} : stage1_right;
    assign stage2_left = shift_val[2] ? {stage1_left[3:0], {4{fill_bit}}} : stage1_left;
    
    // Select final output based on shift direction
    assign final_shift = shift_dir ? stage2_right : stage2_left;
    
    // Register the output
    always @(posedge clk or posedge rst) begin
        if (rst) 
            data_out <= 8'h00;
        else 
            data_out <= final_shift;
    end
endmodule