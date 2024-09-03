/*****************************************************************************
 * help.hpp : Help and About dialogs
 ****************************************************************************
 * Copyright (C) 2007 the VideoLAN team
 *
 * Authors: Jean-Baptiste Kempf <jb (at) videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#ifndef QVLC_HELP_DIALOG_H_
#define QVLC_HELP_DIALOG_H_ 1

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "qt.hpp"

#include "widgets/native/qvlcframe.hpp"
#include "util/singleton.hpp"

/* Auto-generated from .ui files */
#include "ui_about.h"
#include "ui_update.h"

class QEvent;

class HelpDialog : public QVLCFrame
{
    Q_OBJECT
public:
    HelpDialog( qt_intf_t * );
    virtual ~HelpDialog();

public slots:
    void close() override { toggleVisible(); }
};

class AboutDialog : public QVLCDialog
{
    Q_OBJECT
public:
    AboutDialog( qt_intf_t * );

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;
    void showEvent ( QShowEvent * ) override;

private:
    bool b_advanced;
    Ui::aboutWidget ui;

private slots:
    void showLicense();
    void showAuthors();
    void showCredit();
};

#if defined(UPDATE_CHECK)

class UpdateDialog : public QVLCFrame
{
    Q_OBJECT
public:
    UpdateDialog( qt_intf_t * );
    virtual ~UpdateDialog();

    static const QEvent::Type UDOkEvent;
    static const QEvent::Type UDErrorEvent;
    void updateNotify( bool );

private:
    Ui::updateWidget ui;
    update_t *p_update;
    void customEvent( QEvent * ) override;
    bool b_checked;

private slots:
    void close() override { toggleVisible(); }

    void UpdateOrDownload();
};
#endif

#endif
