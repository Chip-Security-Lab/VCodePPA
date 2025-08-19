//SystemVerilog
module config_direction_comp #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input direction,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    wire [$clog2(WIDTH)-1:0] msb_out, lsb_out;
    reg [$clog2(WIDTH)-1:0] encoded_out;
    
    // Instantiate both encoders to run in parallel
    priority_encoder_msb #(
        .WIDTH(WIDTH)
    ) msb_encoder (
        .data_in(data_in),
        .encoded_out(msb_out)
    );
    
    priority_encoder_lsb #(
        .WIDTH(WIDTH)
    ) lsb_encoder (
        .data_in(data_in),
        .encoded_out(lsb_out)
    );
    
    // Select between MSB and LSB priority outputs
    always @(*) begin
        encoded_out = direction ? lsb_out : msb_out;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
        end else begin
            priority_out <= encoded_out;
        end
    end
endmodule

// Optimized MSB priority encoder
module priority_encoder_msb #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output [$clog2(WIDTH)-1:0] encoded_out
);
    // Pre-calculate width parameter
    localparam OUT_WIDTH = $clog2(WIDTH);
    
    // Optimized MSB priority logic using parallel comparisons
    reg [OUT_WIDTH-1:0] result;
    
    always @(*) begin
        result = {OUT_WIDTH{1'b0}};
        
        // Split into parallel sections for balanced path delay
        if (WIDTH >= 4) begin
            if (|data_in[WIDTH-1:WIDTH/2]) begin
                // Upper half has priority
                if (WIDTH >= 8) begin
                    if (|data_in[WIDTH-1:WIDTH*3/4]) begin
                        if (|data_in[WIDTH-1:WIDTH*7/8]) begin
                            result = find_msb_pos(data_in, WIDTH-1, WIDTH*7/8);
                        end else begin
                            result = find_msb_pos(data_in, WIDTH*7/8-1, WIDTH*3/4);
                        end
                    end else begin
                        if (|data_in[WIDTH*3/4-1:WIDTH*5/8]) begin
                            result = find_msb_pos(data_in, WIDTH*3/4-1, WIDTH*5/8);
                        end else begin
                            result = find_msb_pos(data_in, WIDTH*5/8-1, WIDTH/2);
                        end
                    end
                end else begin
                    // For smaller widths
                    result = find_msb_pos(data_in, WIDTH-1, WIDTH/2);
                end
            end else begin
                // Lower half processing
                if (WIDTH >= 8) begin
                    if (|data_in[WIDTH/2-1:WIDTH/4]) begin
                        if (|data_in[WIDTH/2-1:WIDTH*3/8]) begin
                            result = find_msb_pos(data_in, WIDTH/2-1, WIDTH*3/8);
                        end else begin
                            result = find_msb_pos(data_in, WIDTH*3/8-1, WIDTH/4);
                        end
                    end else begin
                        if (|data_in[WIDTH/4-1:WIDTH/8]) begin
                            result = find_msb_pos(data_in, WIDTH/4-1, WIDTH/8);
                        end else begin
                            result = find_msb_pos(data_in, WIDTH/8-1, 0);
                        end
                    end
                end else begin
                    // For smaller widths
                    result = find_msb_pos(data_in, WIDTH/2-1, 0);
                end
            end
        end else begin
            // For very small widths, use simple priority logic
            casez(data_in)
                'b1???: result = 'd3;
                'b01??: result = 'd2;
                'b001?: result = 'd1;
                'b0001: result = 'd0;
                default: result = 'd0;
            endcase
        end
    end
    
    assign encoded_out = result;
    
    // Function to find MSB position in a specific range
    function [OUT_WIDTH-1:0] find_msb_pos;
        input [WIDTH-1:0] data;
        input integer high;
        input integer low;
        integer i;
        begin
            find_msb_pos = {OUT_WIDTH{1'b0}};
            for (i = high; i >= low; i = i - 1) begin
                if (data[i]) find_msb_pos = i[OUT_WIDTH-1:0];
            end
        end
    endfunction
endmodule

// Optimized LSB priority encoder
module priority_encoder_lsb #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output [$clog2(WIDTH)-1:0] encoded_out
);
    // Pre-calculate width parameter
    localparam OUT_WIDTH = $clog2(WIDTH);
    
    // Optimized LSB priority logic using parallel comparisons
    reg [OUT_WIDTH-1:0] result;
    
    always @(*) begin
        result = {OUT_WIDTH{1'b0}};
        
        // Split into parallel sections for balanced path delay
        if (WIDTH >= 4) begin
            if (|data_in[WIDTH/2-1:0]) begin
                // Lower half has priority
                if (WIDTH >= 8) begin
                    if (|data_in[WIDTH/4-1:0]) begin
                        if (|data_in[WIDTH/8-1:0]) begin
                            result = find_lsb_pos(data_in, 0, WIDTH/8-1);
                        end else begin
                            result = find_lsb_pos(data_in, WIDTH/8, WIDTH/4-1);
                        end
                    end else begin
                        if (|data_in[WIDTH*3/8-1:WIDTH/4]) begin
                            result = find_lsb_pos(data_in, WIDTH/4, WIDTH*3/8-1);
                        end else begin
                            result = find_lsb_pos(data_in, WIDTH*3/8, WIDTH/2-1);
                        end
                    end
                end else begin
                    // For smaller widths
                    result = find_lsb_pos(data_in, 0, WIDTH/2-1);
                end
            end else begin
                // Upper half processing
                if (WIDTH >= 8) begin
                    if (|data_in[WIDTH*3/4-1:WIDTH/2]) begin
                        if (|data_in[WIDTH*5/8-1:WIDTH/2]) begin
                            result = find_lsb_pos(data_in, WIDTH/2, WIDTH*5/8-1);
                        end else begin
                            result = find_lsb_pos(data_in, WIDTH*5/8, WIDTH*3/4-1);
                        end
                    end else begin
                        if (|data_in[WIDTH*7/8-1:WIDTH*3/4]) begin
                            result = find_lsb_pos(data_in, WIDTH*3/4, WIDTH*7/8-1);
                        end else begin
                            result = find_lsb_pos(data_in, WIDTH*7/8, WIDTH-1);
                        end
                    end
                end else begin
                    // For smaller widths
                    result = find_lsb_pos(data_in, WIDTH/2, WIDTH-1);
                end
            end
        end else begin
            // For very small widths, use simple priority logic
            casez(data_in)
                'b???1: result = 'd0;
                'b??10: result = 'd1;
                'b?100: result = 'd2;
                'b1000: result = 'd3;
                default: result = 'd0;
            endcase
        end
    end
    
    assign encoded_out = result;
    
    // Function to find LSB position in a specific range
    function [OUT_WIDTH-1:0] find_lsb_pos;
        input [WIDTH-1:0] data;
        input integer low;
        input integer high;
        integer i;
        begin
            find_lsb_pos = {OUT_WIDTH{1'b0}};
            for (i = low; i <= high; i = i + 1) begin
                if (data[i]) find_lsb_pos = i[OUT_WIDTH-1:0];
            end
        end
    endfunction
endmodule