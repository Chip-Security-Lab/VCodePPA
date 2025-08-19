module DistributedIVMU #(parameter CHANNELS = 4)(
    input clk, rst,
    input [CHANNELS-1:0] local_irq [0:3], // 4 sources with CHANNELS each
    output reg [31:0] local_vec [0:3],
    output reg [3:0] irq_out,
    input [3:0] irq_ack
);
    reg [31:0] vector_bases [0:3];
    reg [CHANNELS-1:0] irq_pending [0:3];
    integer i, j;
    
    initial for (i = 0; i < 4; i = i + 1)
        vector_bases[i] = 32'hFF00_0000 + (i << 12);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                irq_pending[i] <= 0;
                irq_out[i] <= 0;
            end
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                irq_pending[i] <= irq_pending[i] | local_irq[i];
                
                if (irq_ack[i]) begin
                    irq_out[i] <= 0;
                    irq_pending[i] <= 0;
                end else if (!irq_out[i] && |irq_pending[i]) begin
                    irq_out[i] <= 1;
                    for (j = CHANNELS-1; j >= 0; j = j - 1) begin
                        if (irq_pending[i][j])
                            local_vec[i] <= vector_bases[i] + (j << 2);
                    end
                end
            end
        end
    end
endmodule