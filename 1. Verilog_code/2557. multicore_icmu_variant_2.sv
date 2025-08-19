//SystemVerilog
module multicore_icmu #(
    parameter CORES = 4,
    parameter INTS_PER_CORE = 8
)(
    input clk, rst_n,
    input [INTS_PER_CORE*CORES-1:0] int_src,
    input [CORES-1:0] ipi_req,
    input [1:0] ipi_target [0:CORES-1],
    output reg [CORES-1:0] int_to_core,
    output reg [2:0] int_id [0:CORES-1],
    input [CORES-1:0] int_ack
);

    reg [INTS_PER_CORE-1:0] int_pending [0:CORES-1];
    reg [CORES-1:0] ipi_pending [0:CORES-1];
    
    integer c, t;
    reg found;
    
    // Priority encoder signals
    wire [INTS_PER_CORE-1:0] int_mask [0:CORES-1];
    wire [2:0] int_priority [0:CORES-1];
    
    // Generate priority masks
    genvar i;
    generate
        for (i = 0; i < CORES; i = i + 1) begin : gen_mask
            assign int_mask[i] = int_pending[i] & ~(int_pending[i] - 1);
        end
    endgenerate
    
    // Priority encoder
    genvar j;
    generate
        for (j = 0; j < CORES; j = j + 1) begin : gen_priority
            assign int_priority[j] = int_mask[j][0] ? 3'd0 :
                                   int_mask[j][1] ? 3'd1 :
                                   int_mask[j][2] ? 3'd2 :
                                   int_mask[j][3] ? 3'd3 :
                                   int_mask[j][4] ? 3'd4 :
                                   int_mask[j][5] ? 3'd5 :
                                   int_mask[j][6] ? 3'd6 :
                                   int_mask[j][7] ? 3'd7 : 3'd0;
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (c = 0; c < CORES; c = c + 1) begin
                int_pending[c] <= {INTS_PER_CORE{1'b0}};
                ipi_pending[c] <= {CORES{1'b0}};
                int_to_core[c] <= 1'b0;
                int_id[c] <= 3'd0;
            end
        end else begin
            for (c = 0; c < CORES; c = c + 1) begin
                int_pending[c] <= int_pending[c] | int_src[c*INTS_PER_CORE +: INTS_PER_CORE];
                
                if (ipi_req[c]) begin
                    ipi_pending[ipi_target[c]][c] <= 1'b1;
                end
                
                if (!int_to_core[c]) begin
                    found = 0;
                    if (|ipi_pending[c]) begin
                        for (t = 0; t < CORES; t = t + 1) begin
                            if (ipi_pending[c][t] && !found) begin
                                int_id[c] <= {1'b1, t[1:0]};
                                int_to_core[c] <= 1'b1;
                                ipi_pending[c][t] <= 1'b0;
                                found = 1;
                            end
                        end
                    end else if (|int_pending[c]) begin
                        int_id[c] <= int_priority[c];
                        int_to_core[c] <= 1'b1;
                        int_pending[c][int_priority[c]] <= 1'b0;
                    end
                end else if (int_ack[c]) begin
                    int_to_core[c] <= 1'b0;
                end
            end
        end
    end

endmodule