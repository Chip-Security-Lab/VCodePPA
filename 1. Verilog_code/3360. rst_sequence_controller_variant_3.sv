//SystemVerilog
//IEEE 1364-2005 Verilog
module rst_sequence_controller (
    input  wire clk,
    input  wire main_rst_n,
    output wire core_rst_n,
    output wire periph_rst_n,
    output wire mem_rst_n
);
    reg [1:0] main_rst_sync;
    reg [2:0] seq_counter;
    
    // Main reset control signals (one-hot encoded)
    reg mem_rst_n_reg;
    reg periph_rst_n_reg;
    reg core_rst_n_reg;
    
    // Output buffer registers for high fanout signals
    reg mem_rst_n_buf1, mem_rst_n_buf2;
    reg periph_rst_n_buf1, periph_rst_n_buf2;
    reg core_rst_n_buf1, core_rst_n_buf2;
    
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            main_rst_sync <= 2'b00;
            seq_counter <= 3'b000;
            mem_rst_n_reg <= 1'b0;
            periph_rst_n_reg <= 1'b0;
            core_rst_n_reg <= 1'b0;
            
            // Clear buffer registers
            mem_rst_n_buf1 <= 1'b0;
            mem_rst_n_buf2 <= 1'b0;
            periph_rst_n_buf1 <= 1'b0;
            periph_rst_n_buf2 <= 1'b0;
            core_rst_n_buf1 <= 1'b0;
            core_rst_n_buf2 <= 1'b0;
        end else begin
            main_rst_sync <= {main_rst_sync[0], 1'b1};
            
            if (main_rst_sync[1] && seq_counter != 3'b111)
                seq_counter <= seq_counter + 1;
            
            // Balanced fanout buffering for reset signals
            mem_rst_n_buf1 <= mem_rst_n_reg;
            mem_rst_n_buf2 <= mem_rst_n_reg;
            periph_rst_n_buf1 <= periph_rst_n_reg;
            periph_rst_n_buf2 <= periph_rst_n_reg;
            core_rst_n_buf1 <= core_rst_n_reg;
            core_rst_n_buf2 <= core_rst_n_reg;
                
            // Direct setting of reset signals based on counter value
            case (seq_counter)
                3'b000: begin
                    mem_rst_n_reg <= 1'b0;
                    periph_rst_n_reg <= 1'b0;
                    core_rst_n_reg <= 1'b0;
                end
                3'b001: begin
                    mem_rst_n_reg <= 1'b1;
                    periph_rst_n_reg <= 1'b0;
                    core_rst_n_reg <= 1'b0;
                end
                3'b010: begin
                    mem_rst_n_reg <= 1'b1;
                    periph_rst_n_reg <= 1'b0;
                    core_rst_n_reg <= 1'b0;
                end
                3'b011, 3'b100, 3'b101, 3'b110: begin
                    mem_rst_n_reg <= 1'b1;
                    periph_rst_n_reg <= 1'b1;
                    core_rst_n_reg <= 1'b0;
                end
                3'b111: begin
                    mem_rst_n_reg <= 1'b1;
                    periph_rst_n_reg <= 1'b1;
                    core_rst_n_reg <= 1'b1;
                end
                default: begin
                    mem_rst_n_reg <= 1'b0;
                    periph_rst_n_reg <= 1'b0;
                    core_rst_n_reg <= 1'b0;
                end
            endcase
        end
    end
    
    // Balanced fanout distribution using buffered outputs
    assign mem_rst_n = (main_rst_sync[1]) ? mem_rst_n_buf1 : mem_rst_n_buf2;
    assign periph_rst_n = (main_rst_sync[0]) ? periph_rst_n_buf1 : periph_rst_n_buf2;
    assign core_rst_n = (seq_counter[0]) ? core_rst_n_buf1 : core_rst_n_buf2;
endmodule