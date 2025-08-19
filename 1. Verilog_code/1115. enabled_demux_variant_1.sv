//SystemVerilog
module enabled_demux (
    input wire [3:0] multiplicand,      // 4-bit multiplicand input
    input wire [3:0] multiplier,        // 4-bit multiplier input
    input wire start,                   // Start signal for multiplication
    input wire clk,                     // Clock signal
    input wire rst_n,                   // Asynchronous active-low reset
    output reg [7:0] product,           // 8-bit product output
    output reg ready                    // Ready flag
);

    reg [4:0] booth_multiplier;         // 5 bits: {multiplier, 1'b0} for Booth encoding
    reg [3:0] booth_multiplicand;       // 4-bit multiplicand register
    reg [7:0] booth_product;            // Booth product register
    reg [2:0] booth_count;              // Booth operation counter (0-4)
    reg booth_busy;                     // Booth operation busy flag

    wire [1:0] booth_code;              // Booth code

    assign booth_code = booth_multiplier[1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_multiplier    <= 5'b0;
            booth_multiplicand  <= 4'b0;
            booth_product       <= 8'b0;
            booth_count         <= 3'd0;
            product             <= 8'b0;
            ready               <= 1'b1;
            booth_busy          <= 1'b0;
        end else begin
            if (start && ready) begin
                booth_multiplier    <= {multiplier, 1'b0};
                booth_multiplicand  <= multiplicand;
                booth_product       <= 8'b0;
                booth_count         <= 3'd0;
                ready               <= 1'b0;
                booth_busy          <= 1'b1;
            end else if (booth_busy) begin
                case (booth_code)
                    2'b01: booth_product[7:0] <= booth_product[7:0] + 
                        ({{4{booth_multiplicand[3]}}, booth_multiplicand} << booth_count);
                    2'b10: booth_product[7:0] <= booth_product[7:0] - 
                        ({{4{booth_multiplicand[3]}}, booth_multiplicand} << booth_count);
                    default: booth_product[7:0] <= booth_product[7:0];
                endcase
                booth_multiplier <= {booth_multiplier[4], booth_multiplier[4:1]};
                booth_count      <= booth_count + 1'b1;

                if (booth_count == 3'd3) begin
                    product   <= booth_product[7:0];
                    ready     <= 1'b1;
                    booth_busy<= 1'b0;
                end
            end
        end
    end

endmodule