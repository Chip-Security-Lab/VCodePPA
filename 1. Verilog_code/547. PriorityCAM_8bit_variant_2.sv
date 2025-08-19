//SystemVerilog
module cam_7 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire write_high,
    input wire [7:0] data_in,
    input wire req,
    input wire ack,
    output reg match,
    output reg [7:0] priority_data,
    output reg data_req
);

    reg [7:0] high_priority, low_priority;
    reg req_reg;
    reg [7:0] data_in_reg;
    reg write_en_reg;
    reg write_high_reg;
    reg req_pending;
    wire high_match, low_match;
    
    // Register input signals
    always @(posedge clk) begin
        if (rst) begin
            req_reg <= 1'b0;
            data_in_reg <= 8'b0;
            write_en_reg <= 1'b0;
            write_high_reg <= 1'b0;
            req_pending <= 1'b0;
        end else if (ack) begin
            req_reg <= req;
            data_in_reg <= data_in;
            write_en_reg <= write_en;
            write_high_reg <= write_high;
            req_pending <= 1'b0;
        end else if (req) begin
            req_pending <= 1'b1;
        end
    end

    // Generate request signal
    assign data_req = req_pending | (req & ~ack);

    // Match detection
    assign high_match = (high_priority == data_in_reg);
    assign low_match = (low_priority == data_in_reg);

    // Main logic
    always @(posedge clk) begin
        if (rst) begin
            high_priority <= 8'b0;
            low_priority <= 8'b0;
            match <= 1'b0;
            priority_data <= 8'b0;
        end else if (req_reg & ack) begin
            if (write_en_reg) begin
                high_priority <= write_high_reg ? data_in_reg : high_priority;
                low_priority <= ~write_high_reg ? data_in_reg : low_priority;
            end else begin
                match <= high_match | low_match;
                priority_data <= high_match ? high_priority : 
                               low_match ? low_priority : priority_data;
            end
        end
    end

endmodule