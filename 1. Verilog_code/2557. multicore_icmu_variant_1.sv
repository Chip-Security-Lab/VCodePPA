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
    
    // Kogge-Stone adder signals for int_id calculation
    reg [2:0] kogge_stone_result [0:CORES-1];
    reg [2:0] kogge_stone_propagate [0:CORES-1];
    reg [2:0] kogge_stone_generate [0:CORES-1];
    reg [2:0] kogge_stone_carry [0:CORES-1];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (c = 0; c < CORES; c = c + 1) begin
                int_pending[c] <= {INTS_PER_CORE{1'b0}};
                ipi_pending[c] <= {CORES{1'b0}};
                int_to_core[c] <= 1'b0;
                int_id[c] <= 3'd0;
                kogge_stone_result[c] <= 3'd0;
                kogge_stone_propagate[c] <= 3'd0;
                kogge_stone_generate[c] <= 3'd0;
                kogge_stone_carry[c] <= 3'd0;
            end
        end else begin
            for (c = 0; c < CORES; c = c + 1) begin
                int_pending[c] <= int_pending[c] | int_src[c*INTS_PER_CORE +: INTS_PER_CORE];
                
                if (ipi_req[c]) begin
                    ipi_pending[ipi_target[c]][c] <= 1'b1;
                end
                
                case ({int_to_core[c], |ipi_pending[c], |int_pending[c]})
                    3'b000: begin
                        // No interrupt pending
                    end
                    3'b010: begin
                        // IPI pending
                        found = 0;
                        for (t = 0; t < CORES; t = t + 1) begin
                            if (ipi_pending[c][t] && !found) begin
                                // Kogge-Stone adder implementation for int_id calculation
                                kogge_stone_propagate[c] = 3'b001; // Base value
                                kogge_stone_generate[c] = {1'b1, t[1:0]}; // Target core ID
                                
                                // Stage 1: Initial propagate and generate
                                kogge_stone_carry[c][0] = kogge_stone_generate[c][0];
                                kogge_stone_carry[c][1] = kogge_stone_generate[c][1] | 
                                                          (kogge_stone_propagate[c][1] & kogge_stone_generate[c][0]);
                                kogge_stone_carry[c][2] = kogge_stone_generate[c][2] | 
                                                          (kogge_stone_propagate[c][2] & kogge_stone_generate[c][1]) |
                                                          (kogge_stone_propagate[c][2] & kogge_stone_propagate[c][1] & kogge_stone_generate[c][0]);
                                
                                // Final sum calculation
                                kogge_stone_result[c][0] = kogge_stone_propagate[c][0] ^ kogge_stone_carry[c][0];
                                kogge_stone_result[c][1] = kogge_stone_propagate[c][1] ^ kogge_stone_carry[c][1];
                                kogge_stone_result[c][2] = kogge_stone_propagate[c][2] ^ kogge_stone_carry[c][2];
                                
                                int_id[c] <= kogge_stone_result[c];
                                int_to_core[c] <= 1'b1;
                                ipi_pending[c][t] <= 1'b0;
                                found = 1;
                            end
                        end
                    end
                    3'b001: begin
                        // Regular interrupt pending
                        // Kogge-Stone adder implementation for get_int_id
                        kogge_stone_propagate[c] = 3'b001; // Base value
                        kogge_stone_generate[c] = get_int_id_kogge_stone(int_pending[c]);
                        
                        // Stage 1: Initial propagate and generate
                        kogge_stone_carry[c][0] = kogge_stone_generate[c][0];
                        kogge_stone_carry[c][1] = kogge_stone_generate[c][1] | 
                                                  (kogge_stone_propagate[c][1] & kogge_stone_generate[c][0]);
                        kogge_stone_carry[c][2] = kogge_stone_generate[c][2] | 
                                                  (kogge_stone_propagate[c][2] & kogge_stone_generate[c][1]) |
                                                  (kogge_stone_propagate[c][2] & kogge_stone_propagate[c][1] & kogge_stone_generate[c][0]);
                        
                        // Final sum calculation
                        kogge_stone_result[c][0] = kogge_stone_propagate[c][0] ^ kogge_stone_carry[c][0];
                        kogge_stone_result[c][1] = kogge_stone_propagate[c][1] ^ kogge_stone_carry[c][1];
                        kogge_stone_result[c][2] = kogge_stone_propagate[c][2] ^ kogge_stone_carry[c][2];
                        
                        int_id[c] <= kogge_stone_result[c];
                        int_to_core[c] <= 1'b1;
                        int_pending[c][kogge_stone_result[c]] <= 1'b0;
                    end
                    3'b100: begin
                        // Interrupt acknowledged
                        if (int_ack[c]) begin
                            int_to_core[c] <= 1'b0;
                        end
                    end
                    default: begin
                        // Other cases maintain current state
                    end
                endcase
            end
        end
    end
    
    function [2:0] get_int_id_kogge_stone;
        input [INTS_PER_CORE-1:0] pending;
        reg [2:0] result;
        integer i;
        begin
            result = 3'd0;
            for (i = 0; i < INTS_PER_CORE; i = i + 1)
                if (pending[i]) result = i[2:0];
            get_int_id_kogge_stone = result;
        end
    endfunction
endmodule