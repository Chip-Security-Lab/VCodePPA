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
    
    wire [CORES-1:0] ipi_active;
    wire [INTS_PER_CORE-1:0] int_active [0:CORES-1];
    wire [2:0] ipi_priority [0:CORES-1];
    wire [2:0] int_priority [0:CORES-1];
    
    // LUT-based priority encoder
    reg [2:0] lut_priority [0:7];
    initial begin
        lut_priority[0] = 3'b000;
        lut_priority[1] = 3'b001;
        lut_priority[2] = 3'b010;
        lut_priority[3] = 3'b011;
        lut_priority[4] = 3'b100;
        lut_priority[5] = 3'b101;
        lut_priority[6] = 3'b110;
        lut_priority[7] = 3'b111;
    end
    
    genvar c, t;
    generate
        for (c = 0; c < CORES; c = c + 1) begin : gen_core
            // IPI priority encoder
            assign ipi_active[c] = |ipi_pending[c];
            assign ipi_priority[c] = lut_priority[ipi_pending[c]];
            
            // Interrupt priority encoder
            assign int_active[c] = |int_pending[c];
            assign int_priority[c] = lut_priority[int_pending[c]];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer c = 0; c < CORES; c = c + 1) begin
                int_pending[c] <= {INTS_PER_CORE{1'b0}};
                ipi_pending[c] <= {CORES{1'b0}};
                int_to_core[c] <= 1'b0;
                int_id[c] <= 3'd0;
            end
        end else begin
            for (integer c = 0; c < CORES; c = c + 1) begin
                // Latch pending interrupts
                int_pending[c] <= int_pending[c] | int_src[c*INTS_PER_CORE +: INTS_PER_CORE];
                
                // Handle IPI requests
                if (ipi_req[c]) begin
                    ipi_pending[ipi_target[c]][c] <= 1'b1;
                end
                
                // Generate interrupts to core
                if (!int_to_core[c]) begin
                    if (ipi_active[c]) begin
                        int_id[c] <= {1'b1, ipi_priority[c][1:0]};
                        int_to_core[c] <= 1'b1;
                        ipi_pending[c][ipi_priority[c]] <= 1'b0;
                    end else if (int_active[c]) begin
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