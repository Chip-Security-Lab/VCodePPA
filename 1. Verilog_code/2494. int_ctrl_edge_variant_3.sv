//SystemVerilog
module int_ctrl_edge #(
    parameter WIDTH = 8
)(
    input clk, rst,
    input [WIDTH-1:0] async_intr,
    output reg [WIDTH-1:0] synced_intr
);
    // First synchronizer stage for async input
    reg [WIDTH-1:0] async_intr_ff;
    // Second stage for edge detection
    reg [WIDTH-1:0] intr_ff;
    
    // Synchronize the asynchronous interrupt first
    always @(posedge clk or posedge rst) begin
        if (rst)
            async_intr_ff <= {WIDTH{1'b0}};
        else
            async_intr_ff <= async_intr;
    end
    
    // Edge detection logic - moved after synchronization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_ff <= {WIDTH{1'b0}};
            synced_intr <= {WIDTH{1'b0}};
        end
        else begin
            intr_ff <= async_intr_ff;
            synced_intr <= async_intr_ff & ~intr_ff;
        end
    end
endmodule