//SystemVerilog - IEEE 1364-2005
module crossbar_dyna_prio #(
    parameter N  = 4,
    parameter DW = 8
) (
    input  wire               clk,
    input  wire               rst_n,  // Added reset signal for pipeline control
    input  wire               valid_in,
    output wire               ready_out,
    
    input  wire [N-1:0][3:0]  prio,
    input  wire [N-1:0][DW-1:0] din,
    
    output wire [N-1:0][DW-1:0] dout,
    output wire               valid_out,
    input  wire               ready_in
);
    // Pipeline stage signals
    reg [N-1:0][3:0]  prio_stage1;
    reg [N-1:0][DW-1:0] din_stage1;
    reg valid_stage1;
    
    reg [N-1:0][DW-1:0] dout_stage2;
    reg valid_stage2;
    
    // Pipeline control signals
    wire stall_pipeline = valid_stage2 && !ready_in;
    wire stage1_ready = !stall_pipeline;
    
    assign ready_out = stage1_ready;
    
    // Stage 1: Register inputs and validate priorities
    reg [N-1:0] valid_prio_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prio_stage1 <= '0;
            din_stage1 <= '0;
            valid_stage1 <= 1'b0;
            valid_prio_stage1 <= '0;
        end
        else if (stage1_ready) begin
            prio_stage1 <= prio;
            din_stage1 <= din;
            valid_stage1 <= valid_in;
            
            // Compute priority validity in the first stage
            for (int i = 0; i < N; i++) begin
                valid_prio_stage1[i] <= (prio[i] < N);
            end
        end
    end
    
    // Stage 2: Crossbar output selection based on priority
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= '0;
            valid_stage2 <= 1'b0;
        end
        else if (!stall_pipeline) begin
            valid_stage2 <= valid_stage1;
            
            // Compute crossbar routing in second stage
            for (int i = 0; i < N; i++) begin
                dout_stage2[i] <= valid_prio_stage1[i] ? din_stage1[prio_stage1[i]] : {DW{1'b0}};
            end
        end
    end
    
    // Output assignment
    assign dout = dout_stage2;
    assign valid_out = valid_stage2;
    
endmodule