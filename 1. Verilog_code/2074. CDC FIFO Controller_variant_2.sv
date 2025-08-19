//SystemVerilog
module cdc_fifo_ctrl #(parameter DEPTH = 8) (
    input wire wr_clk, rd_clk, reset,
    input wire write, read,
    output wire full, empty,
    output reg [$clog2(DEPTH)-1:0] wptr, rptr
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [PTR_WIDTH-1:0] wptr_gray, rptr_gray;
    reg [PTR_WIDTH-1:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [PTR_WIDTH-1:0] rptr_gray_sync1, rptr_gray_sync2;

    // Function: Parallel borrow lookahead subtraction
    function [PTR_WIDTH-1:0] borrow_lookahead_sub;
        input [PTR_WIDTH-1:0] minuend;
        input [PTR_WIDTH-1:0] subtrahend;
        reg [PTR_WIDTH:0] borrow;
        integer k;
        begin
            borrow[0] = 1'b0;
            for (k = 0; k < PTR_WIDTH; k = k + 1) begin
                borrow[k+1] = (~minuend[k] & subtrahend[k]) | ((~minuend[k] | subtrahend[k]) & borrow[k]);
            end
            for (k = 0; k < PTR_WIDTH; k = k + 1) begin
                borrow_lookahead_sub[k] = minuend[k] ^ subtrahend[k] ^ borrow[k];
            end
        end
    endfunction

    // Function: Barrel shifter-based binary to Gray code conversion
    function [PTR_WIDTH-1:0] bin2gray_barrel;
        input [PTR_WIDTH-1:0] bin;
        integer i, j;
        reg [PTR_WIDTH-1:0] stage [0:PTR_WIDTH-1];
        begin
            stage[0] = bin;
            for (i = 0; i < PTR_WIDTH-1; i = i + 1) begin
                for (j = 0; j < PTR_WIDTH; j = j + 1) begin
                    if (j >= (1 << i))
                        stage[i+1][j] = stage[i][j] ^ stage[i][j-(1<<i)];
                    else
                        stage[i+1][j] = stage[i][j];
                end
            end
            bin2gray_barrel = stage[PTR_WIDTH-1] ^ (stage[PTR_WIDTH-1] >> 1);
        end
    endfunction

    //==============================================================
    // Write Pointer Logic: Handles increment and reset of wptr
    //==============================================================
    reg [PTR_WIDTH-1:0] wptr_next;
    always @(*) begin
        wptr_next = borrow_lookahead_sub(wptr, {PTR_WIDTH{1'b1}} ^ { {(PTR_WIDTH-1){1'b0}}, 1'b1 });
    end

    //==============================================================
    // Write Pointer Register Update
    //==============================================================
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else if (write && !full) begin
            wptr <= wptr_next;
        end
    end

    //==============================================================
    // Write Pointer Gray Code Update
    //==============================================================
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (write && !full) begin
            wptr_gray <= bin2gray_barrel(wptr_next);
        end
    end

    //==============================================================
    // Read Pointer Logic: Handles increment and reset of rptr
    //==============================================================
    reg [PTR_WIDTH-1:0] rptr_next;
    always @(*) begin
        rptr_next = borrow_lookahead_sub(rptr, {PTR_WIDTH{1'b1}} ^ { {(PTR_WIDTH-1){1'b0}}, 1'b1 });
    end

    //==============================================================
    // Read Pointer Register Update
    //==============================================================
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rptr <= {PTR_WIDTH{1'b0}};
        end else if (read && !empty) begin
            rptr <= rptr_next;
        end
    end

    //==============================================================
    // Read Pointer Gray Code Update
    //==============================================================
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rptr_gray <= {PTR_WIDTH{1'b0}};
        end else if (read && !empty) begin
            rptr_gray <= bin2gray_barrel(rptr_next);
        end
    end

    //==============================================================
    // Synchronizer for Write Pointer Gray Code in Read Clock Domain
    //==============================================================
    // Stage 1
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            wptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_gray_sync1 <= wptr_gray;
        end
    end
    // Stage 2
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            wptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    //==============================================================
    // Synchronizer for Read Pointer Gray Code in Write Clock Domain
    //==============================================================
    // Stage 1
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            rptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_gray_sync1 <= rptr_gray;
        end
    end
    // Stage 2
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            rptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    //==============================================================
    // Full Flag Generation
    //==============================================================
    assign full = (wptr_gray == {~rptr_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2], rptr_gray_sync2[PTR_WIDTH-3:0]});

    //==============================================================
    // Empty Flag Generation
    //==============================================================
    assign empty = (rptr_gray == wptr_gray_sync2);

endmodule