//SystemVerilog
module AutoBaudUART (
    input clk, rst_n,
    input rx_line,
    output reg [15:0] baud_rate,
    output reg baud_locked
);
    localparam SEARCH  = 3'b001;
    localparam MEASURE = 3'b010; 
    localparam LOCKED  = 3'b100;
    
    reg [2:0] current_state;
    reg [15:0] edge_counter;
    reg last_rx;
    wire falling_edge = last_rx == 1'b1 && rx_line == 1'b0;
    wire rising_edge = last_rx == 1'b0 && rx_line == 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= SEARCH;
            edge_counter <= 0;
            last_rx <= 1;
            baud_locked <= 0;
            baud_rate <= 0;
        end else begin
            last_rx <= rx_line;
            
            if (current_state == SEARCH && falling_edge) begin
                current_state <= MEASURE;
                edge_counter <= 0;
            end
            else if (current_state == MEASURE) begin
                edge_counter <= edge_counter + 1;
                if (rising_edge) begin
                    baud_rate <= edge_counter;
                    current_state <= LOCKED;
                end
            end
            else if (current_state == LOCKED) begin
                baud_locked <= 1;
            end
            else begin
                current_state <= SEARCH;
            end
        end
    end
endmodule