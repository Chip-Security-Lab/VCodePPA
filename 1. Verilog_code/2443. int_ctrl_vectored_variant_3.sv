//SystemVerilog
// Top-level interrupt controller module
module int_ctrl_vectored #(parameter VEC_W=16)(
    input wire clk,
    input wire rst,
    input wire [VEC_W-1:0] int_in,
    input wire [VEC_W-1:0] mask_reg,
    output wire [VEC_W-1:0] int_out
);
    // Internal connections
    wire [VEC_W-1:0] int_in_registered;
    wire [VEC_W-1:0] mask_reg_registered;
    wire [VEC_W-1:0] pending_interrupts;
    
    // Submodule instantiations
    input_synchronizer #(.WIDTH(VEC_W)) input_sync_inst (
        .clk(clk),
        .rst(rst),
        .int_in(int_in),
        .mask_reg(mask_reg),
        .int_in_sync(int_in_registered),
        .mask_reg_sync(mask_reg_registered)
    );
    
    interrupt_tracker #(.WIDTH(VEC_W)) int_track_inst (
        .clk(clk),
        .rst(rst),
        .int_in_reg(int_in_registered),
        .mask_reg_reg(mask_reg_registered),
        .pending_reg(pending_interrupts)
    );
    
    // Output assignment
    assign int_out = pending_interrupts;
endmodule

// Input synchronization submodule
module input_synchronizer #(parameter WIDTH=16)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] int_in,
    input wire [WIDTH-1:0] mask_reg,
    output reg [WIDTH-1:0] int_in_sync,
    output reg [WIDTH-1:0] mask_reg_sync
);
    // Input signal synchronization
    always @(posedge clk) begin
        if(rst) begin
            int_in_sync <= {WIDTH{1'b0}};
            mask_reg_sync <= {WIDTH{1'b0}};
        end
        else begin
            int_in_sync <= int_in;
            mask_reg_sync <= mask_reg;
        end
    end
endmodule

// Interrupt tracking and masking submodule
module interrupt_tracker #(parameter WIDTH=16)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] int_in_reg,
    input wire [WIDTH-1:0] mask_reg_reg,
    output reg [WIDTH-1:0] pending_reg
);
    // Pending interrupt tracking logic
    always @(posedge clk) begin
        if(rst) begin
            pending_reg <= {WIDTH{1'b0}};
        end
        else begin
            pending_reg <= (pending_reg | int_in_reg) & mask_reg_reg;
        end
    end
endmodule