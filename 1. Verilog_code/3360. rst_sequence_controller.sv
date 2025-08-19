module rst_sequence_controller (
    input  wire clk,
    input  wire main_rst_n,
    output wire core_rst_n,
    output wire periph_rst_n,
    output wire mem_rst_n
);
    reg [1:0] main_rst_sync;
    reg [2:0] seq_counter;
    
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            main_rst_sync <= 2'b00;
            seq_counter <= 3'b000;
        end else begin
            main_rst_sync <= {main_rst_sync[0], 1'b1};
            
            if (main_rst_sync[1] && seq_counter != 3'b111)
                seq_counter <= seq_counter + 1;
        end
    end
    
    assign mem_rst_n = (seq_counter >= 3'b001);
    assign periph_rst_n = (seq_counter >= 3'b011);
    assign core_rst_n = (seq_counter >= 3'b111);
endmodule