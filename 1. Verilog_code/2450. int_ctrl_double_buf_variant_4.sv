//SystemVerilog
module int_ctrl_double_buf #(parameter WIDTH=8) (
    input clk, swap,
    input [WIDTH-1:0] new_status,
    output [WIDTH-1:0] current_status
);
    reg [WIDTH-1:0] buf1;
    reg [WIDTH-1:0] new_status_stage1, new_status_stage2, new_status_stage3;
    reg swap_stage1, swap_stage2, swap_stage3;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk) begin
        new_status_stage1 <= new_status;
        swap_stage1 <= swap;
    end
    
    // Pipeline stage 2: Intermediate processing
    always @(posedge clk) begin
        new_status_stage2 <= new_status_stage1;
        swap_stage2 <= swap_stage1;
    end
    
    // Pipeline stage 3: Final processing
    always @(posedge clk) begin
        new_status_stage3 <= new_status_stage2;
        swap_stage3 <= swap_stage2;
    end
    
    // Output buffer update
    always @(posedge clk) begin
        if(swap_stage3) buf1 <= new_status_stage3;
    end
    
    assign current_status = buf1;
endmodule