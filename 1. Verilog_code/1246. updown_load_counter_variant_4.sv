//SystemVerilog
module updown_load_counter (
    input wire clk,           // System clock
    input wire rst_n,         // Active-low asynchronous reset
    input wire load,          // Load control signal
    input wire up_down,       // Direction control (1: count up, 0: count down)
    input wire [7:0] data_in, // Parallel data input for loading
    output reg [7:0] q        // Counter output
);

    // Control signals pipeline registers
    reg load_r;
    reg up_down_r;
    
    // Input data pipeline register
    reg [7:0] data_in_r;
    
    // Next value computation registers
    reg [7:0] next_count_up;
    reg [7:0] next_count_down;
    reg [7:0] next_q;
    
    // Control signals capture and synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_r <= 1'b0;
            up_down_r <= 1'b0;
            data_in_r <= 8'h00;
        end else begin
            load_r <= load;
            up_down_r <= up_down;
            data_in_r <= data_in;
        end
    end
    
    // Computation stage - prepare next values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_count_up <= 8'h00;
            next_count_down <= 8'h00;
        end else begin
            next_count_up <= q + 1'b1;
            next_count_down <= q - 1'b1;
        end
    end
    
    // Next state selection logic
    always @(*) begin
        if (load_r)
            next_q = data_in_r;
        else if (up_down_r)
            next_q = next_count_up;
        else
            next_q = next_count_down;
    end
    
    // Output register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'h00;
        else
            q <= next_q;
    end

endmodule