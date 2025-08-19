//SystemVerilog - IEEE 1364-2005
module crossbar_dyna_prio #(N=4, DW=8) (
    input clk,
    input [N-1:0][3:0] prio,
    input [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    reg [3:0] curr_prio[0:N-1];
    reg [N-1:0][DW-1:0] din_reg;
    reg [N-1:0][3:0] prio_reg;
    reg [N-1:0] valid_prio;
    
    // Pipeline registers for improved path balancing
    reg [N-1:0][DW-1:0] din_stage;
    reg [N-1:0][3:0] prio_stage;
    reg [N-1:0] valid_stage;
    
    integer i;
    
    always @(posedge clk) begin
        // Stage 1: Register inputs to improve timing
        for (i = 0; i < N; i = i + 1) begin
            din_reg[i] <= din[i];
            prio_reg[i] <= prio[i];
            curr_prio[i] <= prio[i];
            // Pre-compute validity check
            valid_prio[i] <= (prio[i] < N);
        end
        
        // Stage 2: Prepare crossbar routing signals
        for (i = 0; i < N; i = i + 1) begin
            din_stage[i] <= din_reg[i];
            prio_stage[i] <= prio_reg[i];
            valid_stage[i] <= valid_prio[i];
        end
        
        // Stage 3: Apply crossbar operation with balanced paths
        for (i = 0; i < N; i = i + 1) begin
            // Split the control path from the data path
            if (valid_stage[i]) begin
                dout[i] <= din_stage[prio_stage[i]];
            end else begin
                dout[i] <= {DW{1'b0}};
            end
        end
    end
endmodule